import Foundation

/// Dates read like handwriting: 十月二十六 in Chinese, October 26 in English.
/// The year only appears when it differs from the current one.
enum KitchenDate {
    static func short(_ date: Date, language: AppLanguage, now: Date = Date()) -> String {
        let calendar = Calendar.current
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        guard language == .chinese else {
            let format = sameYear ? Date.FormatStyle.dateTime.month(.wide).day() : .dateTime.month(.wide).day().year()
            return date.formatted(format.locale(language.locale))
        }
        let body = "\(numeral(month))月\(numeral(day))"
        return sameYear ? body : "\(calendar.component(.year, from: date))年\(body)"
    }

    /// 1...31 as Chinese numerals, e.g. 26 → 二十六.
    static func numeral(_ value: Int) -> String {
        let digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]
        switch value {
        case 0...9: return digits[value]
        case 10: return "十"
        case 11...19: return "十" + digits[value - 10]
        case 20: return "二十"
        case 21...29: return "二十" + digits[value - 20]
        case 30: return "三十"
        case 31: return "三十一"
        default: return String(value)
        }
    }
}
