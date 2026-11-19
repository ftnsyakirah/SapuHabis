'use strict';

const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 50;
const MAX_SEARCH_TERMS = 8;
const MAX_QUERY_LENGTH = 100;

const SORT_OPTIONS = {
  nearest_expiry: 'l.expiry_at ASC',
  price_low_high: 'l.price_sen ASC, l.expiry_at ASC',
  price_high_low: 'l.price_sen DESC, l.expiry_at ASC',
  nearest: 'distance_km ASC, l.expiry_at ASC',
  biggest_discount: 'discount_percent DESC, l.expiry_at ASC',
  newest: 'l.created_at DESC',
};
const DEFAULT_SORT = 'nearest_expiry';
const LISTING_TYPES = new Set(['sale', 'donation']);
const TAG_RE = /^[a-z0-9_]{1,30}$/;
const NUMBER_RE = /^-?(\d+\.?\d*|\.\d+)$/;
const INT_RE = /^-?\d+$/;

const DISCOUNT_SQL =
  'MAX(0, CASE WHEN l.original_price_sen > 0 ' +
  'THEN CAST(ROUND((1.0 - l.price_sen * 1.0 / l.original_price_sen) * 100) AS INTEGER) ' +
  'ELSE 0 END)';

const SCHEMA = `
CREATE TABLE IF NOT EXISTS businesses (
  id      INTEGER PRIMARY KEY,
  name    TEXT NOT NULL,
  address TEXT,
  lat     REAL NOT NULL,
  lng     REAL NOT NULL
);
CREATE TABLE IF NOT EXISTS listings (
  id                 INTEGER PRIMARY KEY,
  business_id        INTEGER NOT NULL REFERENCES businesses(id),
  title              TEXT NOT NULL,
  description        TEXT NOT NULL DEFAULT '',
  category           TEXT NOT NULL,
  price_sen          INTEGER NOT NULL CHECK (price_sen >= 0),
  original_price_sen INTEGER NOT NULL CHECK (original_price_sen >= 0),
  quantity           INTEGER NOT NULL CHECK (quantity >= 0),
  expiry_at          TEXT NOT NULL,              -- UTC, YYYY-MM-DDTHH:MM:SSZ
  pickup_start       TEXT,
  pickup_end         TEXT,
  tags               TEXT NOT NULL DEFAULT ',',  -- ",halal,vegan,"
  listing_type       TEXT NOT NULL DEFAULT 'sale' CHECK (listing_type IN ('sale', 'donation')),
  image_url          TEXT,
  created_at         TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_listings_expiry   ON listings(expiry_at);
CREATE INDEX IF NOT EXISTS idx_listings_price    ON listings(price_sen);
CREATE INDEX IF NOT EXISTS idx_listings_category ON listings(category);
`;

const toIso = (date) => date.toISOString().replace(/\.\d{3}Z$/, 'Z');
const fromIso = (text) => new Date(text);
const senToRm = (sen) => Math.round(sen) / 100;
const rmToSen = (rm) => Math.round(rm * 100);
const encodeTags = (tags) => (tags && tags.length ? `,${tags.join(',')},` : ',');
const decodeTags = (text) => text.split(',').filter(Boolean);
const round = (value, places) => {
  const f = 10 ** places;
  return Math.round(value * f) / f;
};

function haversineKm(lat1, lng1, lat2, lng2) {
  if ([lat1, lng1, lat2, lng2].some((v) => v === null || v === undefined)) return null;
  const rad = (d) => (d * Math.PI) / 180;
  const dp = rad(lat2 - lat1);
  const dl = rad(lng2 - lng1);
  const a = Math.sin(dp / 2) ** 2 + Math.cos(rad(lat1)) * Math.cos(rad(lat2)) * Math.sin(dl / 2) ** 2;
  return 2 * 6371.0088 * Math.asin(Math.min(1, Math.sqrt(a)));
}

function likeContains(text) {
  return `%${text.replace(/\\/g, '\\\\').replace(/%/g, '\\%').replace(/_/g, '\\_')}%`;
}

function usedParams(sql, params) {
  const out = {};
  for (const [key, value] of Object.entries(params)) {
    if (new RegExp(`:${key}\\b`).test(sql)) out[key] = value;
  }
  return out;
}

class QueryError extends Error {
  constructor(details) {
    super(details.join('; '));
    this.details = details;
  }
}

function parseCatalogParams(searchParams) {
  const errors = [];
  const get = (name) => searchParams.get(name);

  const number = (name, { int = false, lo = null, hi = null } = {}) => {
    const raw = get(name);
    if (raw === null || raw.trim() === '') return null;
    const text = raw.trim();
    if (!(int ? INT_RE : NUMBER_RE).test(text)) {
      errors.push(`${name} must be ${int ? 'a whole number' : 'a number'}`);
      return null;
    }
    const value = Number(text);
    if (lo !== null && value < lo) {
      errors.push(`${name} must be at least ${lo}`);
      return null;
    }
    if (hi !== null && value > hi) {
      errors.push(`${name} must be at most ${hi}`);
      return null;
    }
    return value;
  };

  const csv = (name) => {
    const values = [];
    for (const raw of searchParams.getAll(name)) {
      for (const part of raw.split(',')) {
        const v = part.trim().toLowerCase();
        if (v) values.push(v);
      }
    }
    return [...new Set(values)];
  };

  const flag = (name) => {
    const raw = (get(name) || '').trim().toLowerCase();
    if (raw === '') return false;
    if (['1', 'true', 'yes'].includes(raw)) return true;
    if (['0', 'false', 'no'].includes(raw)) return false;
    errors.push(`${name} must be true or false`);
    return false;
  };

  const q = (get('q') || '').trim();
  if (q.length > MAX_QUERY_LENGTH) errors.push(`q must be at most ${MAX_QUERY_LENGTH} characters`);

  const sort = (get('sort') || DEFAULT_SORT).trim();
  if (!(sort in SORT_OPTIONS)) errors.push(`sort must be one of: ${Object.keys(SORT_OPTIONS).join(', ')}`);

  const lat = number('lat', { lo: -90, hi: 90 });
  const lng = number('lng', { lo: -180, hi: 180 });
  if ((lat === null) !== (lng === null)) errors.push('lat and lng must be provided together');
  const hasLocation = lat !== null && lng !== null;

  const maxDistanceKm = number('max_distance_km', { lo: 0 });
  if (maxDistanceKm !== null && !hasLocation) errors.push('max_distance_km needs lat and lng');
  if (sort === 'nearest' && !hasLocation) errors.push('sort=nearest needs lat and lng');

  const minPrice = number('min_price', { lo: 0 });
  const maxPrice = number('max_price', { lo: 0 });
  if (minPrice !== null && maxPrice !== null && minPrice > maxPrice) {
    errors.push('min_price must not be greater than max_price');
  }

  const minDiscount = number('min_discount', { lo: 0, hi: 100 });
  const expiringWithinHours = number('expiring_within_hours', { lo: 0, hi: 24 * 30 });

  const listingTypeRaw = (get('listing_type') || '').trim().toLowerCase();
  const listingType = listingTypeRaw || null;
  if (listingType !== null && !LISTING_TYPES.has(listingType)) {
    errors.push(`listing_type must be one of: ${[...LISTING_TYPES].sort().join(', ')}`);
  }

  const tags = csv('tags');
  for (const tag of tags) {
    if (!TAG_RE.test(tag)) errors.push(`invalid tag '${tag}' (use letters, digits and underscores)`);
  }

  const page = number('page', { int: true, lo: 1, hi: 100000 }) || 1;
  const pageSize = number('page_size', { int: true, lo: 1, hi: MAX_PAGE_SIZE }) || DEFAULT_PAGE_SIZE;
  const includeSoldOut = flag('include_sold_out');

  if (errors.length) throw new QueryError(errors);

  return {
    q,
    categories: csv('category'),
    tags,
    listingType,
    minPrice,
    maxPrice,
    minDiscount,
    expiringWithinHours,
    maxDistanceKm,
    lat,
    lng,
    hasLocation,
    includeSoldOut,
    sort,
    page,
    pageSize,
  };
}

const distanceSql = (p) => (p.hasLocation ? 'haversine(:lat, :lng, b.lat, b.lng)' : 'NULL');

function buildWhere(p, now) {
  const where = ['l.expiry_at > :now']; // TUNJUK MAKANAN EXPIRED
  const args = { now: toIso(now) };

  if (!p.includeSoldOut) where.push('l.quantity > 0');

  p.q
    .toLowerCase()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, MAX_SEARCH_TERMS)
    .forEach((term, i) => {
      args[`q${i}`] = likeContains(term);
      where.push(
        `(l.title LIKE :q${i} ESCAPE '\\' OR l.description LIKE :q${i} ESCAPE '\\' ` +
          `OR l.category LIKE :q${i} ESCAPE '\\' OR b.name LIKE :q${i} ESCAPE '\\' ` +
          `OR l.tags LIKE :q${i} ESCAPE '\\')`,
      );
    });

  if (p.categories.length) {
    const names = p.categories.map((category, i) => {
      args[`cat${i}`] = category;
      return `:cat${i}`;
    });
    where.push(`LOWER(l.category) IN (${names.join(', ')})`);
  }

  p.tags.forEach((tag, i) => {
    args[`tag${i}`] = likeContains(`,${tag},`);
    where.push(`l.tags LIKE :tag${i} ESCAPE '\\'`);
  });

  if (p.listingType) {
    where.push('l.listing_type = :listing_type');
    args.listing_type = p.listingType;
  }
  if (p.minPrice !== null) {
    where.push('l.price_sen >= :min_price_sen');
    args.min_price_sen = rmToSen(p.minPrice);
  }
  if (p.maxPrice !== null) {
    where.push('l.price_sen <= :max_price_sen');
    args.max_price_sen = rmToSen(p.maxPrice);
  }
  if (p.minDiscount !== null) {
    where.push(`${DISCOUNT_SQL} >= :min_discount`);
    args.min_discount = p.minDiscount;
  }
  if (p.expiringWithinHours !== null) {
    where.push('l.expiry_at <= :expiry_cutoff');
    args.expiry_cutoff = toIso(new Date(now.getTime() + p.expiringWithinHours * 3600 * 1000));
  }
  if (p.hasLocation) {
    args.lat = p.lat;
    args.lng = p.lng;
    if (p.maxDistanceKm !== null) {
      where.push(`${distanceSql(p)} <= :max_distance_km`);
      args.max_distance_km = p.maxDistanceKm;
    }
  }
  return { where: where.join(' AND '), args };
}

function serializeListing(row, now) {
  const secondsLeft = (fromIso(row.expiry_at).getTime() - now.getTime()) / 1000;
  const distance = row.distance_km;
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    listing_type: row.listing_type,
    price: senToRm(row.price_sen),
    original_price: senToRm(row.original_price_sen),
    discount_percent: Number(row.discount_percent),
    quantity_left: row.quantity,
    expiry_at: row.expiry_at,
    expires_in_minutes: Math.max(0, Math.floor(secondsLeft / 60)),
    pickup_start: row.pickup_start,
    pickup_end: row.pickup_end,
    tags: decodeTags(row.tags),
    image_url: row.image_url,
    distance_km: distance === null || distance === undefined ? null : round(distance, 2),
    business: {
      id: row.business_id,
      name: row.business_name,
      address: row.business_address,
      lat: row.business_lat,
      lng: row.business_lng,
    },
  };
}

const selectColumns = (p) => `
  l.*,
  b.name AS business_name, b.address AS business_address,
  b.lat AS business_lat, b.lng AS business_lng,
  ${DISCOUNT_SQL} AS discount_percent,
  ${distanceSql(p)} AS distance_km`;

function searchCatalog(db, p, now) {
  const { where, args } = buildWhere(p, now);
  const from = 'FROM listings l JOIN businesses b ON b.id = l.business_id';

  const countSql = `SELECT COUNT(*) AS n ${from} WHERE ${where}`;
  const total = db.prepare(countSql).get(usedParams(countSql, args)).n;

  const sql =
    `SELECT ${selectColumns(p)} ${from} WHERE ${where} ` +
    `ORDER BY ${SORT_OPTIONS[p.sort]}, l.id ASC LIMIT :limit OFFSET :offset`;
  const rows = db
    .prepare(sql)
    .all(usedParams(sql, { ...args, limit: p.pageSize, offset: (p.page - 1) * p.pageSize }));

  const totalPages = total ? Math.ceil(total / p.pageSize) : 0;
  return {
    items: rows.map((r) => serializeListing(r, now)),
    page: p.page,
    page_size: p.pageSize,
    total,
    total_pages: totalPages,
    has_next: p.page < totalPages,
    sort: p.sort,
    filters: {
      q: p.q,
      category: p.categories,
      tags: p.tags,
      listing_type: p.listingType,
      min_price: p.minPrice,
      max_price: p.maxPrice,
      min_discount: p.minDiscount,
      expiring_within_hours: p.expiringWithinHours,
      max_distance_km: p.maxDistanceKm,
      include_sold_out: p.includeSoldOut,
    },
  };
}

function facets(db, now) {
  const base = 'FROM listings l WHERE l.expiry_at > :now AND l.quantity > 0';
  const args = { now: toIso(now) };

  const categories = db
    .prepare(
      `SELECT LOWER(l.category) AS name, COUNT(*) AS count ${base} ` +
        'GROUP BY LOWER(l.category) ORDER BY count DESC, name ASC',
    )
    .all(args);

  const tagCounts = new Map();
  for (const { tags } of db.prepare(`SELECT l.tags ${base}`).all(args)) {
    for (const tag of decodeTags(tags)) tagCounts.set(tag, (tagCounts.get(tag) || 0) + 1);
  }
  const tags = [...tagCounts.entries()]
    .sort((a, b) => b[1] - a[1] || (a[0] < b[0] ? -1 : 1))
    .map(([name, count]) => ({ name, count }));

  const stats = db
    .prepare(
      `SELECT MIN(l.price_sen) AS lo, MAX(l.price_sen) AS hi, MAX(${DISCOUNT_SQL}) AS disc ${base}`,
    )
    .get(args);

  return {
    categories: categories.map((r) => ({ name: r.name, count: r.count })),
    tags,
    min_price: stats.lo === null ? null : senToRm(stats.lo),
    max_price: stats.hi === null ? null : senToRm(stats.hi),
    max_discount_percent: stats.disc || 0,
    sort_options: Object.keys(SORT_OPTIONS),
  };
}

function listingDetail(db, id, p, now) {
  const args = { id, now: toIso(now) };
  if (p.hasLocation) {
    args.lat = p.lat;
    args.lng = p.lng;
  }
  const sql =
    `SELECT ${selectColumns(p)} FROM listings l JOIN businesses b ON b.id = l.business_id ` +
    'WHERE l.id = :id AND l.expiry_at > :now';
  const row = db.prepare(sql).get(usedParams(sql, args));
  return row ? serializeListing(row, now) : null;
}

module.exports = {
  SCHEMA,
  SORT_OPTIONS,
  QueryError,
  parseCatalogParams,
  searchCatalog,
  facets,
  listingDetail,
  haversineKm,
  toIso,
  rmToSen,
  encodeTags,
};
