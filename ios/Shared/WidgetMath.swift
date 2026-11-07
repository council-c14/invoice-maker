import Foundation

/// Arithmetic for the home-screen widget. Same rules as android/src/app/invoicemaker/WidgetMath.java.
enum WidgetMath {
  struct Totals {
    var outstanding = 0.0, overdue = 0.0
    var open = 0, late = 0
  }

  /// `open` is "yyyy-mm-dd|balance" items joined by ";" (written by the page).
  /// An invoice is overdue when its due date is before `today` ("yyyy-mm-dd").
  static func totals(_ open: String, today: String) -> Totals {
    var t = Totals()
    for item in open.split(separator: ";") {
      let parts = item.split(separator: "|", omittingEmptySubsequences: false)
      guard parts.count == 2, let balance = Double(parts[1]), balance > 0 else { continue }
      t.outstanding += balance
      t.open += 1
      let due = String(parts[0])
      if !due.isEmpty && due < today { t.overdue += balance; t.late += 1 }
    }
    t.outstanding = (t.outstanding * 100).rounded() / 100
    t.overdue = (t.overdue * 100).rounded() / 100
    return t
  }

  static func money(_ currency: String, _ amount: Double) -> String {
    let f = NumberFormatter()
    f.locale = Locale(identifier: "en_US")
    f.numberStyle = .decimal
    f.minimumFractionDigits = 2
    f.maximumFractionDigits = 2
    return "\(currency) \(f.string(from: NSNumber(value: amount)) ?? String(format: "%.2f", amount))"
  }

  /// "yyyy-mm-dd" in the phone's time zone, comparable with the due dates.
  static func day(_ date: Date) -> String {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.timeZone = .current
    f.dateFormat = "yyyy-MM-dd"
    return f.string(from: date)
  }
}
