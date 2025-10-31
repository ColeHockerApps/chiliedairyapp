import Combine
import SwiftUI
import Foundation

// MARK: - Date Formatters

public enum DateFormatters {
    public static let dayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        f.locale = Locale.current
        return f
    }()

    public static let dayFull: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        f.locale = Locale.current
        return f
    }()

    public static let timeShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale.current
        return f
    }()

    public static let weekdayShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        f.locale = Locale.current
        return f
    }()

    public static func string(from date: Date, style: DateStyle) -> String {
        switch style {
        case .dayShort: return dayShort.string(from: date)
        case .dayFull: return dayFull.string(from: date)
        case .timeShort: return timeShort.string(from: date)
        case .weekdayShort: return weekdayShort.string(from: date)
        }
    }

    public enum DateStyle {
        case dayShort
        case dayFull
        case timeShort
        case weekdayShort
    }
}

// MARK: - Number Formatters

public enum NumberFormatters {
    public static let decimal1: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 1
        f.maximumFractionDigits = 1
        return f
    }()

    public static let percent0: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .percent
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    public static func string(from value: Double, format: FormatStyle) -> String {
        switch format {
        case .decimal1:
            return decimal1.string(from: NSNumber(value: value)) ?? "\(value)"
        case .percent0:
            return percent0.string(from: NSNumber(value: value)) ?? "\(Int(value * 100))%"
        }
    }

    public enum FormatStyle {
        case decimal1
        case percent0
    }
}

// MARK: - Energy and Satiety Formatters

public enum MealFormatters {
    public static func energyString(_ value: Double) -> String {
        if value == 0 { return "-" }
        if value < 1.5 { return "Low" }
        if value < 2.5 { return "Medium" }
        return "High"
    }

    public static func satietyString(_ value: Double) -> String {
        if value == 0 { return "-" }
        if value < 2.0 { return "Low" }
        if value < 4.0 { return "Medium" }
        return "High"
    }

    public static func hungerString(_ value: Double) -> String {
        if value == 0 { return "-" }
        if value < 2.0 { return "Light" }
        if value < 4.0 { return "Moderate" }
        return "Strong"
    }
}

// MARK: - Flavor Distribution Strings

public enum FlavorFormatters {
    public static func flavorRatioString(_ ratio: Double) -> String {
        NumberFormatters.string(from: ratio, format: .percent0)
    }

    public static func topFlavorString(_ distribution: [FlavorTag: Double]) -> String {
        guard let top = distribution.max(by: { $0.value < $1.value }) else { return "—" }
        return "\(top.key.title) \(flavorRatioString(top.value))"
    }

    public static func balanceSummary(_ distribution: [FlavorTag: Double]) -> String {
        let nonZero = distribution.filter { $0.value > 0 }
        if nonZero.count < 3 { return "Low variety" }
        if nonZero.count == 3 { return "Balanced" }
        return "Rich variety"
    }
}

// MARK: - Insight Strings

public enum InsightFormatters {
    public static func summary(for insights: [InsightItem]) -> String {
        guard !insights.isEmpty else { return "No insights yet" }
        let titles = insights.map { $0.title }
        return titles.joined(separator: ", ")
    }

    public static func categoryEmoji(_ category: InsightCategory) -> String {
        switch category {
        case .balance: return "⚖️"
        case .energy: return "⚡️"
        case .satiety: return "🍽️"
        case .habits: return "🕒"
        case .flavor: return "🌶️"
        }
    }
}

// MARK: - Time Description

public enum TimeFormatters {
    public static func timeAgo(from date: Date, now: Date = .now) -> String {
        let diff = Int(now.timeIntervalSince(date))
        if diff < 60 { return "\(diff)s ago" }
        if diff < 3600 { return "\(diff/60)m ago" }
        if diff < 86400 { return "\(diff/3600)h ago" }
        if diff < 172800 { return "Yesterday" }
        let days = diff / 86400
        return "\(days)d ago"
    }

    public static func partOfDay(for date: Date, calendar: Calendar = .current) -> String {
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Morning"
        case 12..<17: return "Afternoon"
        case 17..<22: return "Evening"
        default: return "Night"
        }
    }
}
