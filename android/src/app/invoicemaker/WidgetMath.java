package app.invoicemaker;

import java.util.Locale;

/** Pure arithmetic for the home-screen widget (no Android imports, so it can be tested on any JVM). */
final class WidgetMath {
  private WidgetMath() { }

  /** Totals of the open invoices as of {@code today}. */
  static final class Totals {
    double outstanding, overdue;
    int open, late;
  }

  /**
   * @param open  open invoices as "yyyy-mm-dd|balance" joined by ';' (written by the page)
   * @param today "yyyy-mm-dd"; an invoice is overdue when its due date is before today
   */
  static Totals totals(String open, String today) {
    Totals t = new Totals();
    if (open == null || open.isEmpty()) return t;
    for (String item : open.split(";")) {
      String[] p = item.split("\\|");
      if (p.length != 2) continue;
      double bal;
      try { bal = Double.parseDouble(p[1]); } catch (NumberFormatException e) { continue; }
      if (bal <= 0) continue;
      t.outstanding += bal;
      t.open++;
      if (!p[0].isEmpty() && p[0].compareTo(today) < 0) { t.overdue += bal; t.late++; }
    }
    t.outstanding = Math.round(t.outstanding * 100) / 100.0;
    t.overdue = Math.round(t.overdue * 100) / 100.0;
    return t;
  }

  /** Amounts travel as text so large figures keep their cents (a float would not). */
  static double parse(String s) {
    try { return Double.parseDouble(s); } catch (Exception e) { return 0; }
  }

  static String money(String currency, double amount) {
    return String.format(Locale.US, "%s %,.2f", currency, amount);
  }
}
