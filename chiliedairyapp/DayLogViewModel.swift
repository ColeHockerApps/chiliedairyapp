import Combine
import SwiftUI
import Foundation

@MainActor
public final class DayLogViewModel: ObservableObject {
    // Store & deps
    private let store: PersistenceStore
    private let stats: StatsEngine
    private let calendar: Calendar

    // Date scope
    @Published public var selectedDate: Date

    // Output
    @Published public private(set) var mealsForDay: [MealEntry] = []
    @Published public private(set) var summary: DailySummary = .init(date: Date(), totalMeals: 0, avgSatiety: 0, avgEnergy: 0, favoriteFlavor: nil)

    // Draft for new/edit
    @Published public var draftName: String = ""
    @Published public var draftType: MealType = .meal
    @Published public var draftSatiety: Int = 3
    @Published public var draftEnergy: EnergyLevel = .medium
    @Published public var draftFlavors: Set<FlavorTag> = []
    @Published public var draftNotes: String = ""
    @Published public private(set) var isEditing: Bool = false
    private var editingID: UUID?

    // Filters (local to the day view)
    @Published public var minSatiety: Int? = nil
    @Published public var energyIn: Set<EnergyLevel> = []
    @Published public var flavorIn: Set<FlavorTag> = []
    @Published public var search: String = ""

    private var bag = Set<AnyCancellable>()

    // Init
    public init(
        store: PersistenceStore = .shared,
        stats: StatsEngine = .shared,
        calendar: Calendar = .current,
        date: Date = .now
    ) {
        self.store = store
        self.stats = stats
        self.calendar = calendar
        self.selectedDate = calendar.startOfDay(for: date)

        bind()
        refresh()
    }

    // MARK: - Bindings

    private func bind() {
        Publishers.CombineLatest4(
            store.$meals,
            $selectedDate.removeDuplicates(by: { Calendar.current.isDate($0, inSameDayAs: $1) }),
            filtersPublisher(),
            Just(())
        )
        .sink { [weak self] _,_,_,_ in self?.refresh() }
        .store(in: &bag)

        // Recompute summary when mealsForDay changes
        $mealsForDay
            .sink { [weak self] _ in self?.recomputeSummary() }
            .store(in: &bag)
    }

    private func filtersPublisher() -> AnyPublisher<String, Never> {
        Publishers.CombineLatest4($minSatiety, $energyIn, $flavorIn, $search)
            .map { _,_,_,_ in "" } // only for invalidation
            .eraseToAnyPublisher()
    }

    // MARK: - Public API: Day switch

    public func goToToday() {
        selectedDate = calendar.startOfDay(for: Date())
    }

    public func previousDay() {
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }

    public func nextDay() {
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }

    // MARK: - Public API: Draft helpers

    public func toggleFlavor(_ tag: FlavorTag) {
        if draftFlavors.contains(tag) { draftFlavors.remove(tag) } else { draftFlavors.insert(tag) }
    }

    public func resetDraft() {
        draftName = ""
        draftType = .meal
        draftSatiety = 3
        draftEnergy = .medium
        draftFlavors = []
        draftNotes = ""
        isEditing = false
        editingID = nil
    }

    public func loadDraft(from entry: MealEntry) {
        draftName = entry.name
        draftType = entry.type
        draftSatiety = entry.satietyLevel
        draftEnergy = entry.energyAfter
        draftFlavors = Set(entry.flavorTags)
        draftNotes = entry.notes ?? ""
        isEditing = true
        editingID = entry.id
    }

    // MARK: - Public API: CRUD

    @discardableResult
    public func addFromDraft() throws -> MealEntry {
        try validateDraft()
        let when = calendar.date(
            bySettingHour: calendar.component(.hour, from: Date()),
            minute: calendar.component(.minute, from: Date()),
            second: 0,
            of: selectedDate
        ) ?? selectedDate

        let entry = MealEntry(
            date: when,
            name: draftName.trimmingCharacters(in: .whitespacesAndNewlines),
            type: draftType,
            satietyLevel: draftSatiety,
            energyAfter: draftEnergy,
            flavorTags: Array(draftFlavors),
            notes: draftNotes.isEmpty ? nil : draftNotes
        )
        let created = store.addMeal(entry)
        resetDraft()
        HapticsManager.shared.success()
        return created
    }

    public func updateFromDraft() throws {
        guard isEditing, let id = editingID else { throw ValidationError.invalidState }
        try validateDraft()

        guard let current = mealsForDay.first(where: { $0.id == id }) ?? store.meals.first(where: { $0.id == id }) else {
            throw ValidationError.notFound
        }

        var updated = current
        updated.name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.type = draftType
        updated.satietyLevel = clamp(draftSatiety, min: 1, max: 5)
        updated.energyAfter = draftEnergy
        updated.flavorTags = Array(draftFlavors)
        updated.notes = draftNotes.isEmpty ? nil : draftNotes

        store.updateMeal(updated)
        resetDraft()
        HapticsManager.shared.success()
    }

    public func delete(_ id: UUID) {
        store.removeMeal(id: id)
        HapticsManager.shared.warning()
    }

    // MARK: - Queries

    public func filteredMeals() -> [MealEntry] {
        var result = mealsForDay

        if let minS = minSatiety {
            result = result.filter { $0.satietyLevel >= minS }
        }
        if !energyIn.isEmpty {
            result = result.filter { energyIn.contains($0.energyAfter) }
        }
        if !flavorIn.isEmpty {
            result = result.filter { !flavorIn.isDisjoint(with: Set($0.flavorTags)) }
        }
        let needle = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !needle.isEmpty {
            result = result.filter {
                "\($0.name) \($0.notes ?? "")".lowercased().contains(needle)
            }
        }
        return result.sorted { $0.date < $1.date }
    }

    // MARK: - Private

    private func refresh() {
        mealsForDay = store.meals(on: selectedDate, calendar: calendar)
            .sorted { $0.date < $1.date }
    }

    private func recomputeSummary() {
        summary = stats.makeDailySummary(for: selectedDate, store: store, calendar: calendar)
    }

    private func validateDraft() throws {
        if draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw ValidationError.emptyName
        }
        if !(1...5).contains(draftSatiety) {
            throw ValidationError.satietyOutOfRange
        }
    }

    private func clamp<T: Comparable>(_ v: T, min lo: T, max hi: T) -> T { max(lo, min(v, hi)) }

    // MARK: - Errors

    public enum ValidationError: Error, LocalizedError {
        case emptyName
        case satietyOutOfRange
        case invalidState
        case notFound

        public var errorDescription: String? {
            switch self {
            case .emptyName: return "Name is required."
            case .satietyOutOfRange: return "Satiety must be 1...5."
            case .invalidState: return "Invalid editing state."
            case .notFound: return "Item not found."
            }
        }
    }
}
