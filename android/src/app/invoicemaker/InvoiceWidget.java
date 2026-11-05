package app.invoicemaker;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.view.View;
import android.widget.RemoteViews;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Home-screen widget: outstanding, overdue, collected this month, and shortcuts to a new invoice or quotation.
 * The page sends a summary after every save (MainActivity.Bridge.updateWidget); overdue is recalculated here,
 * hourly, from each open invoice's due date, so it stays right without opening the app.
 */
public class InvoiceWidget extends AppWidgetProvider {
  static final String PREFS = "widget";

  @Override
  public void onUpdate(Context c, AppWidgetManager m, int[] ids) {
    for (int id : ids) m.updateAppWidget(id, build(c));
  }

  static void refreshAll(Context c) {
    AppWidgetManager m = AppWidgetManager.getInstance(c);
    int[] ids = m.getAppWidgetIds(new ComponentName(c, InvoiceWidget.class));
    if (ids.length > 0) m.updateAppWidget(ids, build(c));
  }

  static RemoteViews build(Context c) {
    RemoteViews v = new RemoteViews(c.getPackageName(), R.layout.widget);
    v.setOnClickPendingIntent(R.id.root, open(c, "", 0));
    v.setOnClickPendingIntent(R.id.btn_invoice, open(c, "new/invoice", 1));
    v.setOnClickPendingIntent(R.id.btn_quote, open(c, "new/quote", 2));

    SharedPreferences p = c.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    if (!p.contains("cur")) {
      v.setTextViewText(R.id.outstanding, "—");
      v.setTextViewText(R.id.open_count, "Open the app to show your figures");
      return v;
    }
    String cur = p.getString("cur", "MVR");
    String today = new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date());
    WidgetMath.Totals t = WidgetMath.totals(p.getString("open", ""), today);

    v.setTextViewText(R.id.outstanding, WidgetMath.money(cur, t.outstanding));
    v.setTextViewText(R.id.open_count, t.open + (t.open == 1 ? " open invoice" : " open invoices"));
    boolean late = t.late > 0;
    v.setViewVisibility(R.id.overdue, late ? View.GONE : View.VISIBLE);
    v.setViewVisibility(R.id.overdue_alert, late ? View.VISIBLE : View.GONE);
    v.setTextViewText(late ? R.id.overdue_alert : R.id.overdue, WidgetMath.money(cur, t.overdue));
    v.setTextViewText(R.id.collected_label, "Collected · " + p.getString("month", ""));
    v.setTextViewText(R.id.collected, WidgetMath.money(cur, WidgetMath.parse(p.getString("collected", "0"))));
    v.setTextViewText(R.id.synced, p.getString("synced", ""));
    return v;
  }

  private static PendingIntent open(Context c, String route, int code) {
    Intent i = new Intent(c, MainActivity.class)
        .setData(Uri.parse("invoicemaker://open/" + route))
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    return PendingIntent.getActivity(c, code, i, PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
  }
}
