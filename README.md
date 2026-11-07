# Invoice Maker

Quotations, invoices, customers and customer reports in a single page (`public/index.html`).

Records are saved only in the browser that created them (localStorage). Nothing is sent to a server,
so people sharing the link never see each other's data. Clearing the browser's site data deletes the
records: use **Business settings → Download backup** regularly, and **Restore backup** to move to
another device or browser.

## Deploy

Served as a static Cloudflare Worker. The Worker is connected to this repo through Cloudflare's Git
integration, so every push to `main` deploys.

## iPhone and iPad

The site is an installable web app: in Safari, **Share → Add to Home Screen** gives an Invoice Maker icon that
opens full screen and works offline (`manifest.webmanifest`, `sw.js`, `apple-touch-icon.png`). The **iPhone app**
item on the site shows these steps. On iPhone, CSV and backup files open the share sheet (Save to Files).

### Native iOS app with Home Screen widget (`ios/`)

A small SwiftUI app that runs the same `public/index.html` in WebKit, plus a WidgetKit widget
(small: outstanding and overdue; medium: also collected this month, + Invoice and + Quotation).
The page sends the widget a summary after every save through an app group; the widget recalculates
overdue at midnight. Printing uses AirPrint (or Save as PDF); CSV and backups use the share sheet.

GitHub Actions (`.github/workflows/ios.yml`) builds it on a Mac for the simulator and runs the widget
arithmetic tests on every change. To install it on an iPhone or publish it you need a Mac with Xcode and an
Apple Developer account:

1. `brew install xcodegen`, then `cd ios && xcodegen` and open `InvoiceMaker.xcodeproj`.
2. Set your team on both targets, and change the bundle IDs (`app.invoicemaker`, `app.invoicemaker.widget`)
   and the app group (`group.app.invoicemaker`) to ones registered to your account.
3. Run on your iPhone, or Product → Archive to upload to TestFlight / the App Store.

## Android app

`android/` wraps the same `public/index.html` in a small native app (package `app.invoicemaker`).
It works offline, has no internet permission, and keeps records in the app's own storage on the phone.
Printing opens Android's print dialog (choose **Save as PDF**); CSV and backup files open a save dialog.

Build (JDK 17+, Android SDK with `platforms;android-36` and `build-tools;36.0.0`):

```bash
ANDROID_HOME=~/android-sdk KEYSTORE=~/invoice-maker.jks KEYSTORE_PASS=... VERSION_CODE=2 VERSION_NAME=1.1 android/build.sh
```

The app includes a home-screen widget (outstanding, overdue, collected this month, + Invoice / + Quotation).
The page sends it a summary after every save; the widget recalculates overdue hourly from due dates.
`build.sh` runs the widget arithmetic test (`android/test`) on the plain JVM before packaging.

`build.sh` also copies the APK to `public/invoice-maker.apk`, which the website offers under **Android app**.

The keystore is not in this repo. Every update must be signed with the same keystore,
otherwise Android refuses to install it over the old app.

## Brand

`brand/icon.svg` is the app icon, `brand/logo.svg` the wordmark; PNG exports sit next to them.
