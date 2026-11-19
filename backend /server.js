'use strict';

const http = require('node:http');
const { DatabaseSync } = require('node:sqlite');
const catalog = require('./catalog');
const { seedDemoDataIfEmpty } = require('./seed');

function createApp({ dbPath = process.env.CATALOG_DB || 'catalog.db', now = () => new Date(), seed = true } = {}) {
  const db = new DatabaseSync(dbPath);
  db.function('haversine', { deterministic: true }, catalog.haversineKm);
  db.exec(catalog.SCHEMA);
  if (seed) seedDemoDataIfEmpty(db, now());

  const corsOrigin = process.env.CORS_ORIGIN || '*';

  const handler = (req, res) => {
    const send = (status, body) => {
      const text = JSON.stringify(body);
      res.writeHead(status, {
        'Content-Type': 'application/json; charset=utf-8',
        'Content-Length': Buffer.byteLength(text),
        'Access-Control-Allow-Origin': corsOrigin,
      });
      res.end(text);
    };

    try {
      if (req.method === 'OPTIONS') {
        res.writeHead(204, {
          'Access-Control-Allow-Origin': corsOrigin,
          'Access-Control-Allow-Methods': 'GET, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        });
        return res.end();
      }
      if (req.method !== 'GET') return send(405, { error: 'method_not_allowed' });

      const url = new URL(req.url, 'http://localhost');
      const path = url.pathname.replace(/\/+$/, '') || '/';

      if (path === '/api/health') return send(200, { status: 'ok' });

      if (path === '/api/catalog') {
        const params = catalog.parseCatalogParams(url.searchParams);
        return send(200, catalog.searchCatalog(db, params, now()));
      }
      if (path === '/api/catalog/facets') return send(200, catalog.facets(db, now()));

      const detail = path.match(/^\/api\/catalog\/(\d+)$/);
      if (detail) {
        const params = catalog.parseCatalogParams(url.searchParams);
        const item = catalog.listingDetail(db, Number(detail[1]), params, now());
        return item ? send(200, item) : send(404, { error: 'not_found' });
      }
      return send(404, { error: 'not_found' });
    } catch (err) {
      if (err instanceof catalog.QueryError) {
        return send(400, { error: 'invalid_query', details: err.details });
      }
      console.error(err);
      return send(500, { error: 'server_error' });
    }
  };

  return { handler, db, close: () => db.close() };
}

if (require.main === module) {
  const app = createApp();
  const port = Number(process.env.PORT || 8000);
  http.createServer(app.handler).listen(port, '0.0.0.0', () => {
    console.log(`SapuHabis catalog API listening on http://0.0.0.0:${port}`);
  });
}

module.exports = { createApp };
