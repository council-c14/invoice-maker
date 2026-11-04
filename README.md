# Invoice Maker

Quotations, invoices, customers and customer reports. Runs as a Cloudflare Worker with a D1 database.

- `public/index.html` – the app
- `src/api.js` – storage API (`GET /api/billing`, `PUT`/`DELETE /api/billing/:kind/:id`)
- `src/worker.js` – serves `public/` and sends `/api/billing` to the API

## Setup (once)

1. Create the database and put its id in `wrangler.toml` (`database_id`):

   ```bash
   npx wrangler d1 create invoice-maker
   ```

2. Add repository secrets `CLOUDFLARE_API_TOKEN` (Workers Scripts and D1 edit) and `CLOUDFLARE_ACCOUNT_ID`.

Every push to `main` deploys. The table is created on the first request.

There is no login: anyone with the link can read and edit. Put Cloudflare Access in front of it if that matters.
