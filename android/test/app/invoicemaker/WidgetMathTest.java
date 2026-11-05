package app.invoicemaker;

public class WidgetMathTest {
  static void check(boolean ok, String what) { if (!ok) throw new AssertionError(what); System.out.println("ok  " + what); }
  public static void main(String[] a) {
    WidgetMath.Totals t = WidgetMath.totals("2026-11-01|1000.50;2026-11-05|200;2026-12-05|12960.00", "2026-11-05");
    check(t.open == 3, "three open invoices");
    check(t.outstanding == 14160.50, "outstanding " + t.outstanding);
    check(t.late == 1 && t.overdue == 1000.50, "only the one due before today is overdue (due today is not)");
    t = WidgetMath.totals("2026-11-01|1000.50;2026-11-05|200", "2026-11-06");
    check(t.late == 2 && t.overdue == 1200.50, "next day both are overdue");
    t = WidgetMath.totals("", "2026-11-05");
    check(t.open == 0 && t.outstanding == 0, "nothing open");
    t = WidgetMath.totals("bad;2026-11-01|x;|50;2026-11-01|0;2026-11-01|-5", "2026-11-05");
    check(t.open == 1 && t.outstanding == 50 && t.late == 0, "skips malformed, zero and negative; missing due date is not overdue");
    t = WidgetMath.totals("2026-01-01|0.1;2026-01-01|0.2", "2026-11-05");
    check(t.outstanding == 0.3 && t.overdue == 0.3, "no float drift (0.1 + 0.2)");
    check(WidgetMath.money("MVR", 1234567.891).equals("MVR 1,234,567.89"), "money format " + WidgetMath.money("MVR", 1234567.891));
    check(WidgetMath.money("USD", WidgetMath.parse("987654.32")).equals("USD 987,654.32"), "large amounts keep cents");
    check(WidgetMath.parse("nope") == 0, "bad text parses to 0");
  }
}
