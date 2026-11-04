# Invoice Maker

Quotations, invoices, customers and customer reports in a single page (`public/index.html`).

Records are saved only in the browser that created them (localStorage). Nothing is sent to a server,
so people sharing the link never see each other's data. Clearing the browser's site data deletes the
records: use **Business settings → Download backup** regularly, and **Restore backup** to move to
another device or browser.

## Deploy

Served as a static Cloudflare Worker. The Worker is connected to this repo through Cloudflare's Git
integration, so every push to `main` deploys.

## Android app

`android/` wraps the same `public/index.html` in a small native app (package `app.invoicemaker`).
It works offline, has no internet permission, and keeps records in the app's own storage on the phone.
Printing opens Android's print dialog (choose **Save as PDF**); CSV and backup files open a save dialog.

Build (JDK 17+, Android SDK with `platforms;android-36` and `build-tools;36.0.0`):

```bash
ANDROID_HOME=~/android-sdk KEYSTORE=~/invoice-maker.jks KEYSTORE_PASS=... VERSION_CODE=2 VERSION_NAME=1.1 android/build.sh
```

The keystore is not in this repo. Every update must be signed with the same keystore,
otherwise Android refuses to install it over the old app.

## Brand

`brand/icon.svg` is the app icon, `brand/logo.svg` the wordmark; PNG exports sit next to them.
