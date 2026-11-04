# Invoice Maker

Quotations, invoices, customers and customer reports in a single page (`public/index.html`).

Records are saved only in the browser that created them (localStorage). Nothing is sent to a server,
so people sharing the link never see each other's data. Clearing the browser's site data deletes the
records: use **Business settings → Download backup** regularly, and **Restore backup** to move to
another device or browser.

## Deploy

Served as a static Cloudflare Worker. The Worker is connected to this repo through Cloudflare's Git
integration, so every push to `main` deploys.
