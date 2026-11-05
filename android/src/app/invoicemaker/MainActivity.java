package app.invoicemaker;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Insets;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.print.PrintAttributes;
import android.print.PrintManager;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import android.widget.FrameLayout;
import android.view.WindowInsets;
import android.webkit.JavascriptInterface;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Toast;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;

/** Runs public/index.html from the APK. Records stay in this app's WebView storage on the device. */
public class MainActivity extends Activity {
  private static final int PICK_FILE = 1, SAVE_FILE = 2;
  private WebView web;
  private FrameLayout root;
  private ValueCallback<Uri[]> fileCallback;
  private String pendingSave;

  @Override
  protected void onCreate(Bundle state) {
    super.onCreate(state);
    boolean night = (getResources().getConfiguration().uiMode & android.content.res.Configuration.UI_MODE_NIGHT_MASK)
        == android.content.res.Configuration.UI_MODE_NIGHT_YES;
    root = new FrameLayout(this);
    web = new WebView(this);
    root.addView(web, new FrameLayout.LayoutParams(-1, -1));
    setContentView(root);
    applyBars(night);

    WebSettings s = web.getSettings();
    s.setJavaScriptEnabled(true);
    s.setDomStorageEnabled(true); // localStorage holds the records
    s.setAllowFileAccess(true);
    s.setAllowContentAccess(false);

    web.setWebViewClient(new WebViewClient() {
      @Override
      public boolean shouldOverrideUrlLoading(WebView v, WebResourceRequest req) {
        Uri u = req.getUrl();
        if ("file".equals(u.getScheme())) return false;
        try { startActivity(new Intent(Intent.ACTION_VIEW, u)); } catch (Exception ignored) { }
        return true;
      }
    });
    web.setWebChromeClient(new WebChromeClient() {
      @Override
      public boolean onShowFileChooser(WebView v, ValueCallback<Uri[]> cb, FileChooserParams params) {
        if (fileCallback != null) fileCallback.onReceiveValue(null);
        fileCallback = cb;
        try { startActivityForResult(params.createIntent(), PICK_FILE); }
        catch (Exception e) { fileCallback = null; return false; }
        return true;
      }
    });
    web.addJavascriptInterface(new Bridge(), "AndroidBridge");

    // Android 15+ draws behind the system bars; keep the page clear of them and of the keyboard.
    if (Build.VERSION.SDK_INT >= 35) {
      root.setOnApplyWindowInsetsListener((View v, WindowInsets insets) -> {
        Insets i = insets.getInsets(WindowInsets.Type.systemBars() | WindowInsets.Type.ime() | WindowInsets.Type.displayCutout());
        v.setPadding(i.left, i.top, i.right, i.bottom);
        return WindowInsets.CONSUMED;
      });
    }
    if (Build.VERSION.SDK_INT >= 33) {
      getOnBackInvokedDispatcher().registerOnBackInvokedCallback(0, this::goBack);
    }

    if (state != null) web.restoreState(state);
    else web.loadUrl("file:///android_asset/index.html");
  }

  /** Matches the window, status bar and navigation bar to the page's light or dark theme. */
  @SuppressWarnings("deprecation")
  private void applyBars(boolean dark) {
    int bg = dark ? 0xFF121211 : 0xFFF5F5F2;
    root.setBackgroundColor(bg);
    web.setBackgroundColor(bg);
    Window w = getWindow();
    if (Build.VERSION.SDK_INT < 35) { w.setStatusBarColor(bg); w.setNavigationBarColor(bg); }
    if (Build.VERSION.SDK_INT >= 30) {
      int light = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS | WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS;
      w.getInsetsController().setSystemBarsAppearance(dark ? 0 : light, light);
    } else if (Build.VERSION.SDK_INT >= 23) {
      int flags = View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR | (Build.VERSION.SDK_INT >= 26 ? View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR : 0);
      View d = w.getDecorView();
      d.setSystemUiVisibility(dark ? d.getSystemUiVisibility() & ~flags : d.getSystemUiVisibility() | flags);
    }
  }

  private void goBack() {
    if (web.canGoBack()) web.goBack(); else finish();
  }

  @Override
  @SuppressWarnings("deprecation")
  public void onBackPressed() { goBack(); }

  @Override
  protected void onSaveInstanceState(Bundle out) {
    super.onSaveInstanceState(out);
    web.saveState(out);
  }

  @Override
  protected void onActivityResult(int req, int result, Intent data) {
    super.onActivityResult(req, result, data);
    if (req == PICK_FILE && fileCallback != null) {
      fileCallback.onReceiveValue(WebChromeClient.FileChooserParams.parseResult(result, data));
      fileCallback = null;
    } else if (req == SAVE_FILE) {
      String text = pendingSave;
      pendingSave = null;
      if (result != RESULT_OK || data == null || data.getData() == null || text == null) return;
      try (OutputStream o = getContentResolver().openOutputStream(data.getData())) {
        o.write(text.getBytes(StandardCharsets.UTF_8));
        Toast.makeText(this, "File saved", Toast.LENGTH_SHORT).show();
      } catch (Exception e) {
        Toast.makeText(this, "Could not save the file", Toast.LENGTH_LONG).show();
      }
    }
  }

  /** Called from the page: window.AndroidBridge.print(...) and saveFile(...). */
  class Bridge {
    @JavascriptInterface
    public void print(String title) {
      runOnUiThread(() -> {
        PrintManager pm = (PrintManager) getSystemService(PRINT_SERVICE);
        PrintAttributes attrs = new PrintAttributes.Builder().setMediaSize(PrintAttributes.MediaSize.ISO_A4).build();
        pm.print(title, web.createPrintDocumentAdapter(title), attrs);
      });
    }

    @JavascriptInterface
    public void setDark(boolean dark) {
      runOnUiThread(() -> applyBars(dark));
    }

    @JavascriptInterface
    public void saveFile(String name, String mime, String text) {
      runOnUiThread(() -> {
        pendingSave = text;
        Intent i = new Intent(Intent.ACTION_CREATE_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE).setType(mime).putExtra(Intent.EXTRA_TITLE, name);
        startActivityForResult(i, SAVE_FILE);
      });
    }
  }
}
