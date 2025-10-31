import Combine
import SwiftUI
import Foundation

@MainActor
public final class HabitsViewModel: ObservableObject {
    // Store & deps
    private let store: PersistenceStore
    private let calendar: Calendar

    // Date scope
    @Published public var selectedDate: Date

    // Output
    @Published public private(set) var snacksForDay: [SnackEvent] = []
    @Published public private(set) var avgHungerForDay: Double = 0

    // Draft
    @Published public var draftReason: SnackReason = .hunger
    @Published public var draftHunger: Int = 3
    @Published public var draftNote: String = ""
    @Published public private(set) var isEditing: Bool = false
    private var editingID: UUID?

    // Filters (local)
    @Published public var minHunger: Int? = nil
    @Published public var reasonIn: Set<SnackReason> = []
    @Published public var search: String = ""

    // Weekly stats
    @Published public private(set) var weeklyReasonStats: [ReasonStat] = []
    @Published public private(set) var weeklyAvgHunger: Double = 0
    @Published public var weeklyRange: DateRangeKind = .thisWeek

    private var bag = Set<AnyCancellable>()

    public init(
        store: PersistenceStore = .shared,
        calendar: Calendar = .current,
        date: Date = .now
    ) {
        self.store = store
        self.calendar = calendar
        self.selectedDate = calendar.startOfDay(for: date)
        bind()
        refresh()
        recomputeWeekly()
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest3(
            store.$snacks,
            $selectedDate.removeDuplicates(by: { Calendar.current.isDate($0, inSameDayAs: $1) }),
            filtersPublisher()
        )
        .sink { [weak self] _,_,_ in
            self?.refresh()
        }
        .store(in: &bag)

        Publishers.CombineLatest(store.$snacks, $weeklyRange)
            .sink { [weak self] _,_ in
                self?.recomputeWeekly()
            }
            .store(in: &bag)
    }

    private func filtersPublisher() -> AnyPublisher<Void, Never> {
        Publishers.CombineLatest3($minHunger, $reasonIn, $search)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    // MARK: - Navigation

    public func goToToday() {
        selectedDate = calendar.startOfDay(for: Date())
    }

    public func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    public func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    // MARK: - Draft

    public func resetDraft() {
        draftReason = .hunger
        draftHunger = 3
        draftNote = ""
        isEditing = false
        editingID = nil
    }

    public func loadDraft(from event: SnackEvent) {
        draftReason = event.reason
        draftHunger = event.hungerLevel
        draftNote = event.note ?? ""
        isEditing = true
        editingID = event.id
    }

    public func quickSelect(reason: SnackReason) {
        draftReason = reason
        HapticsManager.shared.selection()
    }

    public func setHunger(_ level: Int) {
        draftHunger = clamp(level, min: 1, max: 5)
        HapticsManager.shared.selection()
    }

    // MARK: - CRUD

    @discardableResult
    public func addFromDraft() throws -> SnackEvent {
        try validateDraft()
        let when = alignTime(to: Date())
        let event = SnackEvent(
            date: when,
            reason: draftReason,
            hungerLevel: draftHunger,
            note: draftNote.isEmpty ? nil : draftNote
        )
        let created = store.addSnack(event)
        resetDraft()
        HapticsManager.shared.success()
        return created
    }

    public func updateFromDraft() throws {
        guard isEditing, let id = editingID else { throw ValidationError.invalidState }
        try validateDraft()

        guard let current = snacksForDay.first(where: { $0.id == id }) ?? store.snacks.first(where: { $0.id == id }) else {
            throw ValidationError.notFound
        }

        var updated = current
        updated.reason = draftReason
        updated.hungerLevel = clamp(draftHunger, min: 1, max: 5)
        updated.note = draftNote.isEmpty ? nil : draftNote

        store.updateSnack(updated)
        resetDraft()
        HapticsManager.shared.success()
    }

    public func delete(_ id: UUID) {
        store.removeSnack(id: id)
        HapticsManager.shared.warning()
    }

    // MARK: - Queries

    public func filteredSnacks() -> [SnackEvent] {
        var result = snacksForDay
        if let minH = minHunger {
            result = result.filter { $0.hungerLevel >= minH }
        }
        if !reasonIn.isEmpty {
            result = result.filter { reasonIn.contains($0.reason) }
        }
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            result = result.filter { ($0.note ?? "").lowercased().contains(needle) }
        }
        return result.sorted { $0.date < $1.date }
    }

    // MARK: - Weekly Stats

    public struct ReasonStat: Identifiable, Hashable {
        public let id = UUID()
        public let reason: SnackReason
        public let count: Int
        public let ratio: Double
    }

    private func recomputeWeekly() {
        let r = weeklyRange.resolve(calendar: calendar)
        let items = store.snacks(in: r.start...r.end, calendar: calendar)
        weeklyAvgHunger = items.averageHunger()

        let counts = items.reasonDistribution()
        let total = max(1, counts.values.reduce(0, +))
        var stats: [ReasonStat] = []
        for reason in SnackReason.allCases {
            let c = counts[reason] ?? 0
            stats.append(.init(reason: reason, count: c, ratio: Double(c) / Double(total)))
        }
        weeklyReasonStats = stats.sorted { $0.count > $1.count }
    }

    // MARK: - Internals

    private func refresh() {
        snacksForDay = store.snacks(on: selectedDate, calendar: calendar)
            .sorted { $0.date < $1.date }
        avgHungerForDay = snacksForDay.averageHunger()
    }

    private func alignTime(to date: Date) -> Date {
        let h = calendar.component(.hour, from: date)
        let m = calendar.component(.minute, from: date)
        return calendar.date(bySettingHour: h, minute: m, second: 0, of: selectedDate) ?? selectedDate
    }

    private func validateDraft() throws {
        if !(1...5).contains(draftHunger) { throw ValidationError.hungerOutOfRange }
    }

    private func clamp<T: Comparable>(_ v: T, min lo: T, max hi: T) -> T { max(lo, min(v, hi)) }

    // MARK: - Errors

    public enum ValidationError: Error, LocalizedError {
        case hungerOutOfRange
        case invalidState
        case notFound

        public var errorDescription: String? {
            switch self {
            case .hungerOutOfRange: return "Hunger must be 1...5."
            case .invalidState: return "Invalid editing state."
            case .notFound: return "Item not found."
            }
        }
    }
}
