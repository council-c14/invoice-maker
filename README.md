# Invoice Maker

Quotations, invoices, customers and customer reports. Runs as a Cloudflare Worker with a D1 database.

- `public/index.html` – the app
- `src/api.js` – storage API (`GET /api/billing`, `PUT`/`DELETE /api/billing/:kind/:id`)
- `src/worker.js` – serves `public/` and sends `/api/billing` to the API

## Deploy

The Worker is connected to this repo through Cloudflare's Git integration, so every push to `main` deploys.
The D1 database (`invoice-maker`) is created on the first deploy, and the table on the first request.

There is no login: anyone with the link can read and edit. Put Cloudflare Access in front of it if that matters.
