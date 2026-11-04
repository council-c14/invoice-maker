// Static files in public/ are served by the assets binding; anything else (the API) reaches this Worker.
import { onRequest } from './api.js';

export default {
  async fetch(request, env) {
    const { pathname } = new URL(request.url);
    if (pathname === '/api/billing' || pathname.startsWith('/api/billing/')) {
      const route = pathname.slice('/api/billing'.length).split('/').filter(Boolean);
      return onRequest({ request, env, params: { route } });
    }
    return env.ASSETS.fetch(request);
  },
};
