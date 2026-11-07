import SwiftUI
import WidgetKit

/// What the app last shared through the app group (see WebController.updateWidget).
struct Summary {
  var currency = "MVR", open = "", month = "", synced = ""
  var collected = 0.0
  var hasData = false

  static func load() -> Summary {
    guard let shared = UserDefaults(suiteName: "group.app.invoicemaker"),
          let currency = shared.string(forKey: "cur") else { return Summary() }
    return Summary(currency: currency,
                   open: shared.string(forKey: "open") ?? "",
                   month: shared.string(forKey: "month") ?? "",
                   synced: shared.string(forKey: "synced") ?? "",
                   collected: Double(shared.string(forKey: "collected") ?? "") ?? 0,
                   hasData: true)
  }

  /// Shown in the widget gallery before the app has any figures.
  static let sample = Summary(currency: "MVR", open: "2000-01-01|540;2999-01-01|12960", month: "November",
                              synced: "Today", collected: 4300, hasData: true)
}

struct Entry: TimelineEntry {
  let date: Date
  let summary: Summary
  var totals: WidgetMath.Totals { WidgetMath.totals(summary.open, today: WidgetMath.day(date)) }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: .now, summary: .sample) }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    let summary = Summary.load()
    completion(Entry(date: .now, summary: context.isPreview && !summary.hasData ? .sample : summary))
  }

  /// One entry now and one at each of the next two midnights, so "overdue" moves on without opening the app.
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let summary = Summary.load(), calendar = Calendar.current
    let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now)
    let after = calendar.date(byAdding: .day, value: 1, to: tomorrow) ?? tomorrow
    completion(Timeline(entries: [Date.now, tomorrow, after].map { Entry(date: $0, summary: summary) }, policy: .atEnd))
  }
}

private extension Color {
  static func pair(_ light: (Double, Double, Double), _ dark: (Double, Double, Double)) -> Color {
    Color(UIColor { traits in
      let c = traits.userInterfaceStyle == .dark ? dark : light
      return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
    })
  }
  static let ink = pair((0.106, 0.106, 0.098), (0.925, 0.922, 0.898))
  static let surface = pair((1, 1, 1), (0.106, 0.106, 0.098))
  static let chip = pair((0.945, 0.945, 0.929), (0.165, 0.165, 0.153))
  static let danger = pair((0.647, 0.196, 0.118), (0.949, 0.569, 0.490))
}

struct WidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: Entry

  var body: some View {
    let s = entry.summary, t = entry.totals
    Group {
      if !s.hasData {
        VStack(alignment: .leading, spacing: 6) {
          header(s)
          Spacer()
          Text("Open Invoice Maker to show your figures").font(.footnote).foregroundStyle(.secondary)
        }
      } else if family == .systemSmall {
        small(s, t)
      } else {
        medium(s, t)
      }
    }
    .containerBackground(for: .widget) { Color.surface }
    .widgetURL(URL(string: "invoicemaker://open/"))
  }

  private func header(_ s: Summary) -> some View {
    HStack(spacing: 6) {
      Image("Mark").resizable().frame(width: 18, height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
      Text("Invoice Maker").font(.caption.weight(.semibold)).foregroundStyle(Color.ink).lineLimit(1)
      Spacer(minLength: 4)
      Text(s.synced).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
    }
  }

  private func label(_ text: String) -> some View {
    Text(text).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
  }

  private func openCount(_ t: WidgetMath.Totals) -> String {
    t.open == 1 ? "1 open invoice" : "\(t.open) open invoices"
  }

  private func small(_ s: Summary, _ t: WidgetMath.Totals) -> some View {
    VStack(alignment: .leading, spacing: 3) {
      header(s)
      Spacer(minLength: 2)
      label("Outstanding")
      Text(WidgetMath.money(s.currency, t.outstanding)).font(.title3.weight(.semibold))
        .foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
      label(openCount(t))
      Spacer(minLength: 2)
      if t.late > 0 {
        Text("\(WidgetMath.money(s.currency, t.overdue)) overdue").font(.caption.weight(.semibold))
          .foregroundStyle(Color.danger).lineLimit(1).minimumScaleFactor(0.6)
      } else {
        label("Nothing overdue")
      }
    }
  }

  private func medium(_ s: Summary, _ t: WidgetMath.Totals) -> some View {
    VStack(spacing: 10) {
      header(s)
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          label("Outstanding")
          Text(WidgetMath.money(s.currency, t.outstanding)).font(.title2.weight(.semibold))
            .foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.5)
          label(openCount(t))
        }
        Spacer(minLength: 0)
        VStack(alignment: .leading, spacing: 2) {
          label("Overdue")
          Text(WidgetMath.money(s.currency, t.overdue)).font(.subheadline.weight(.semibold))
            .foregroundStyle(t.late > 0 ? Color.danger : Color.ink).lineLimit(1).minimumScaleFactor(0.6)
          label("Collected · \(s.month)").padding(.top, 4)
          Text(WidgetMath.money(s.currency, s.collected)).font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.ink).lineLimit(1).minimumScaleFactor(0.6)
        }
      }
      HStack(spacing: 8) {
        Link(destination: URL(string: "invoicemaker://open/new/invoice")!) { pill("+ Invoice", primary: true) }
        Link(destination: URL(string: "invoicemaker://open/new/quote")!) { pill("+ Quotation", primary: false) }
      }
    }
  }

  private func pill(_ title: String, primary: Bool) -> some View {
    Text(title).font(.footnote.weight(.semibold))
      .frame(maxWidth: .infinity).padding(.vertical, 7)
      .foregroundStyle(primary ? Color.surface : Color.ink)
      .background(Capsule().fill(primary ? Color.ink : Color.chip))
  }
}

@main
struct InvoiceWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "InvoiceWidget", provider: Provider()) { WidgetView(entry: $0) }
      .configurationDisplayName("Invoice Maker")
      .description("Outstanding and overdue at a glance, with shortcuts to a new invoice or quotation.")
      .supportedFamilies([.systemSmall, .systemMedium])
  }
}
