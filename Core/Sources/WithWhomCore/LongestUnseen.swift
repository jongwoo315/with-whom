import Foundation

public enum LongestUnseen {
    /// 마지막으로 만난 지 가장 오래된 사람과 달력 날짜 기준 날 수를 고른다.
    /// `last`가 `now`보다 뒤인 항목은 앞으로 잡힌 약속이라 무시한다. 날 수가 같으면 이름 오름차순 첫 번째.
    public static func pick(_ lastSeen: [(name: String, last: Date)], now: Date, calendar: Calendar) -> (name: String, days: Int)? {
        let today = calendar.startOfDay(for: now)
        return lastSeen
            .filter { $0.last <= now }
            .map { (name: $0.name, days: calendar.dateComponents([.day], from: calendar.startOfDay(for: $0.last), to: today).day ?? 0) }
            .min { ($1.days, $0.name) < ($0.days, $1.name) }
    }
}
