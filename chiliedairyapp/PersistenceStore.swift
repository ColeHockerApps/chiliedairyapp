import Combine
import SwiftUI
import Foundation
import UniformTypeIdentifiers

@MainActor
public final class PersistenceStore: ObservableObject {
    public static let shared = PersistenceStore()

    @Published public private(set) var meals: [MealEntry] = []
    @Published public private(set) var snacks: [SnackEvent] = []
    @Published public private(set) var insights: [InsightItem] = []

    private let autosaveDebounce: TimeInterval = 0.6
    private let schemaVersion: Int = 1
    private let filename = "chilie_diary_store.json"
    private var cancellables = Set<AnyCancellable>()

    private init() {
        load()
        setupAutosave()
    }

    // MARK: - Public CRUD (Meals)

    @discardableResult
    public func addMeal(_ entry: MealEntry) -> MealEntry {
        var e = entry
        if meals.contains(where: { $0.id == e.id }) { e = withNewID(e) }
        meals.append(e)
        meals.sort { $0.date < $1.date }
        return e
    }

    public func updateMeal(_ entry: MealEntry) {
        guard let idx = meals.firstIndex(where: { $0.id == entry.id }) else { return }
        meals[idx] = entry
        meals.sort { $0.date < $1.date }
    }

    public func removeMeal(id: UUID) {
        meals.removeAll { $0.id == id }
    }

    // MARK: - Public CRUD (Snacks)

    @discardableResult
    public func addSnack(_ event: SnackEvent) -> SnackEvent {
        var s = event
        if snacks.contains(where: { $0.id == s.id }) { s = withNewID(s) }
        snacks.append(s)
        snacks.sort { $0.date < $1.date }
        return s
    }

    public func updateSnack(_ event: SnackEvent) {
        guard let idx = snacks.firstIndex(where: { $0.id == event.id }) else { return }
        snacks[idx] = event
        snacks.sort { $0.date < $1.date }
    }

    public func removeSnack(id: UUID) {
        snacks.removeAll { $0.id == id }
    }

    // MARK: - Public CRUD (Insights)

    @discardableResult
    public func addInsight(_ item: InsightItem) -> InsightItem {
        var i = item
        if insights.contains(where: { $0.id == i.id }) { i = withNewID(i) }
        insights.append(i)
        insights.sort { $0.date > $1.date }
        return i
    }

    public func removeInsight(id: UUID) {
        insights.removeAll { $0.id == id }
    }

    // MARK: - Queries

    public func meals(in range: ClosedRange<Date>, calendar: Calendar = .current) -> [MealEntry] {
        meals.filter { range.contains($0.date) }
    }

    public func snacks(in range: ClosedRange<Date>, calendar: Calendar = .current) -> [SnackEvent] {
        snacks.filter { range.contains($0.date) }
    }

    public func meals(on day: Date, calendar: Calendar = .current) -> [MealEntry] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
        return meals(in: start...end, calendar: calendar)
    }

    public func snacks(on day: Date, calendar: Calendar = .current) -> [SnackEvent] {
        let start = calendar.startOfDay(for: day)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
        return snacks(in: start...end, calendar: calendar)
    }

    // MARK: - Export / Import

    public func exportData() -> Data? {
        let payload = StorePayload(version: schemaVersion, meals: meals, snacks: snacks, insights: insights)
        return try? JSONEncoder.stable.encode(payload)
    }

    public func exportString() -> String? {
        guard let data = exportData() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func export(to url: URL) throws {
        guard let data = exportData() else { throw StoreError.encodeFailed }
        try ensureDirectory(url.deletingLastPathComponent())
        try data.write(to: url, options: [.atomic])
    }

    public func `import`(from data: Data, replace: Bool = true) throws {
        let payload = try JSONDecoder.stable.decode(StorePayload.self, from: data)
        if replace {
            meals = payload.meals
            snacks = payload.snacks
            insights = payload.insights
        } else {
            merge(meals: payload.meals, snacks: payload.snacks, insights: payload.insights)
        }
        try saveNow()
    }

    public func wipeAll() throws {
        meals.removeAll()
        snacks.removeAll()
        insights.removeAll()
        try saveNow()
    }

    // MARK: - Load / Save

    private func load() {
        let url = storeURL()
        guard FileManager.default.fileExists(atPath: url.path) else {
            bootstrapIfNeeded()
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder.stable.decode(StorePayload.self, from: data)
            meals = payload.meals
            snacks = payload.snacks
            insights = payload.insights
        } catch {
            meals = []
            snacks = []
            insights = []
        }
    }

    private func setupAutosave() {
        Publishers.CombineLatest3($meals, $snacks, $insights)
            .debounce(for: .seconds(autosaveDebounce), scheduler: RunLoop.main)
            .sink { [weak self] _, _, _ in
                Task { try? await self?.saveAsync() }
            }
            .store(in: &cancellables)
    }

    @discardableResult
    private func saveNow() throws -> URL {
        let payload = StorePayload(version: schemaVersion, meals: meals, snacks: snacks, insights: insights)
        let data = try JSONEncoder.stable.encode(payload)
        let url = storeURL()
        try ensureDirectory(url.deletingLastPathComponent())
        try data.write(to: url, options: [.atomic])
        return url
    }

    private func saveAsync() async throws {
        let payload = StorePayload(version: schemaVersion, meals: meals, snacks: snacks, insights: insights)
        let data = try JSONEncoder.stable.encode(payload)
        let url = storeURL()
        try ensureDirectory(url.deletingLastPathComponent())
        try data.write(to: url, options: [.atomic])
    }

    // MARK: - Helpers

    private func merge(meals newMeals: [MealEntry], snacks newSnacks: [SnackEvent], insights newInsights: [InsightItem]) {
        let mealIDs = Set(meals.map { $0.id })
        let snackIDs = Set(snacks.map { $0.id })
        let insightIDs = Set(insights.map { $0.id })

        meals.append(contentsOf: newMeals.filter { !mealIDs.contains($0.id) })
        snacks.append(contentsOf: newSnacks.filter { !snackIDs.contains($0.id) })
        insights.append(contentsOf: newInsights.filter { !insightIDs.contains($0.id) })

        meals.sort { $0.date < $1.date }
        snacks.sort { $0.date < $1.date }
        insights.sort { $0.date > $1.date }
    }

    private func withNewID(_ entry: MealEntry) -> MealEntry {
        MealEntry(id: UUID(), date: entry.date, name: entry.name, type: entry.type,
                  satietyLevel: entry.satietyLevel, energyAfter: entry.energyAfter,
                  flavorTags: entry.flavorTags, notes: entry.notes)
    }

    private func withNewID(_ event: SnackEvent) -> SnackEvent {
        SnackEvent(id: UUID(), date: event.date, reason: event.reason,
                   hungerLevel: event.hungerLevel, note: event.note)
    }

    private func withNewID(_ item: InsightItem) -> InsightItem {
        InsightItem(id: UUID(), date: item.date, title: item.title,
                    description: item.description, category: item.category)
    }

    private func storeURL() -> URL {
        let dir = applicationSupportDirectory().appendingPathComponent("ChilieDiary", isDirectory: true)
        return dir.appendingPathComponent(filename, conformingTo: UTType.json)
    }

    private func applicationSupportDirectory() -> URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    private func ensureDirectory(_ dir: URL) throws {
        var isDir: ObjCBool = false
        if !FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir) || !isDir.boolValue {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    private func bootstrapIfNeeded() {
        meals = []
        snacks = []
        insights = []
        try? saveNow()
    }
}

// MARK: - Payload

private struct StorePayload: Codable {
    let version: Int
    let meals: [MealEntry]
    let snacks: [SnackEvent]
    let insights: [InsightItem]
}

// MARK: - Errors

public enum StoreError: Error {
    case encodeFailed
    case decodeFailed
    case writeFailed
}

// MARK: - Stable Coders

fileprivate extension JSONEncoder {
    static var stable: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.sortedKeys]
        return e
    }
}

fileprivate extension JSONDecoder {
    static var stable: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
