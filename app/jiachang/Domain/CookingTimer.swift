import Foundation

struct CookingTimer: Equatable {
    enum State: Equatable {
        case running
        case paused
        case finished
    }

    static let minuteRange = 1...1_440

    let duration: TimeInterval
    let stepIndex: Int
    private(set) var state: State = .running
    private(set) var remaining: TimeInterval
    private(set) var deadline: Date?

    init(minutes: Int, stepIndex: Int, now: Date) {
        duration = TimeInterval(minutes) * 60
        remaining = duration
        self.stepIndex = stepIndex
        deadline = now.addingTimeInterval(duration)
    }

    var remainingSeconds: Int { Int(ceil(remaining)) }

    /// Returns true only for the transition to finished, never on subsequent ticks.
    mutating func tick(now: Date) -> Bool {
        guard state == .running, let deadline else { return false }
        remaining = max(0, deadline.timeIntervalSince(now))
        guard remaining == 0 else { return false }
        state = .finished
        self.deadline = nil
        return true
    }

    mutating func pause(now: Date) {
        guard state == .running, let deadline else { return }
        remaining = max(0, deadline.timeIntervalSince(now))
        self.deadline = nil
        state = .paused
    }

    mutating func resume(now: Date) {
        guard state == .paused else { return }
        deadline = now.addingTimeInterval(remaining)
        state = .running
    }

    mutating func reset() {
        remaining = duration
        deadline = nil
        state = .paused
    }
}

/// A suggestion, not an automatic timer. Ambiguous or multiple durations require manual input.
enum CookingDurationParser {
    private static let pattern = #"(?<![0-9A-Za-z])([+\-]?[0-9零〇一二两三四五六七八九十百千.,．/]+(?:\s*(?:[-–—~～至到]|to)\s*[0-9零〇一二两三四五六七八九十百千.,．/]+)?)\s*(?:分钟|minutes?\b|min\b)"#

    static func suggestedMinutes(in text: String) -> Int? {
        // Bundled bilingual content has a defined separator; it is one instruction, not two timers.
        let content = text.components(separatedBy: " · ")[0]
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))
        guard matches.count == 1,
              let range = Range(matches[0].range(at: 1), in: content) else { return nil }
        let token = String(content[range])
        let minutes: Int?
        if token.allSatisfy({ "0123456789".contains($0) }) {
            minutes = Int(token)
        } else {
            minutes = chineseInteger(token)
        }
        guard let minutes, CookingTimer.minuteRange.contains(minutes) else { return nil }
        return minutes
    }

    private static func chineseInteger(_ token: String) -> Int? {
        let digits: [Character: Int] = ["零": 0, "〇": 0, "一": 1, "二": 2, "两": 2, "三": 3,
                                         "四": 4, "五": 5, "六": 6, "七": 7, "八": 8, "九": 9]
        let units: [Character: Int] = ["十": 10, "百": 100, "千": 1_000]
        var total = 0
        var digit: Int?
        var previousUnit = 10_000
        for character in token {
            if let value = digits[character] {
                guard digit == nil || digit == 0 else { return nil }
                digit = value
            } else if let unit = units[character] {
                guard unit < previousUnit, digit != 0 else { return nil }
                total += (digit ?? 1) * unit
                digit = nil
                previousUnit = unit
            } else {
                return nil
            }
        }
        return total + (digit ?? 0)
    }
}
