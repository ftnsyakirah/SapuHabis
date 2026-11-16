from __future__ import annotations

import math
import os
import re
import sqlite3
from datetime import datetime, timedelta, timezone

from flask import Flask, current_app, g, jsonify, request

ISO_FORMAT = "%Y-%m-%dT%H:%M:%SZ"
DEFAULT_PAGE_SIZE = 20
MAX_PAGE_SIZE = 50
MAX_SEARCH_TERMS = 8
MAX_QUERY_LENGTH = 100

SORT_OPTIONS = {
    "nearest_expiry": "l.expiry_at ASC",
    "price_low_high": "l.price_sen ASC, l.expiry_at ASC",
    "price_high_low": "l.price_sen DESC, l.expiry_at ASC",
    "nearest": "distance_km ASC, l.expiry_at ASC",
    "biggest_discount": "discount_percent DESC, l.expiry_at ASC",
    "newest": "l.created_at DESC",
}
DEFAULT_SORT = "nearest_expiry"
LISTING_TYPES = {"sale", "donation"}
TAG_RE = re.compile(r"^[a-z0-9_]{1,30}$")

DISCOUNT_SQL = (
    "MAX(0, CASE WHEN l.original_price_sen > 0 "
    "THEN CAST(ROUND((1.0 - l.price_sen * 1.0 / l.original_price_sen) * 100) AS INTEGER) "
    "ELSE 0 END)"
)

SCHEMA = """
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
"""

def utc_now() -> datetime:
    return datetime.now(timezone.utc).replace(microsecond=0)


def to_iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime(ISO_FORMAT)


def from_iso(text: str) -> datetime:
    return datetime.strptime(text, ISO_FORMAT).replace(tzinfo=timezone.utc)


def haversine_km(lat1, lng1, lat2, lng2):
    if None in (lat1, lng1, lat2, lng2):
        return None
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = p2 - p1, math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * 6371.0088 * math.asin(min(1.0, math.sqrt(a)))


def sen_to_rm(sen: int) -> float:
    return round(sen / 100, 2)


def rm_to_sen(rm: float) -> int:
    return int(round(rm * 100))


def encode_tags(tags) -> str:
    return "," + ",".join(tags) + "," if tags else ","


def decode_tags(text: str) -> list[str]:
    return [t for t in text.split(",") if t]


def like_contains(text: str) -> str:
    """LIKE pattern matching `text` anywhere, with %, _ and \\ treated literally."""
    escaped = text.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_")
    return f"%{escaped}%"


class QueryError(Exception):
    def __init__(self, details: list[str]):
        super().__init__("; ".join(details))
        self.details = details


def parse_catalog_params(args) -> dict:
    """Validate query-string parameters. Raises QueryError listing every problem."""
    errors: list[str] = []

    def number(name, *, kind=float, lo=None, hi=None):
        raw = args.get(name)
        if raw is None or raw.strip() == "":
            return None
        try:
            value = kind(raw)
        except ValueError:
            errors.append(f"{name} must be {'a whole number' if kind is int else 'a number'}")
            return None
        if kind is float and not math.isfinite(value):
            errors.append(f"{name} must be a finite number")
            return None
        if lo is not None and value < lo:
            errors.append(f"{name} must be at least {lo}")
            return None
        if hi is not None and value > hi:
            errors.append(f"{name} must be at most {hi}")
            return None
        return value

    def csv(name):
        values: list[str] = []
        for raw in args.getlist(name):
            values.extend(part.strip().lower() for part in raw.split(",") if part.strip())
        return list(dict.fromkeys(values))  

    def flag(name):
        raw = (args.get(name) or "").strip().lower()
        if raw == "":
            return False
        if raw in ("1", "true", "yes"):
            return True
        if raw in ("0", "false", "no"):
            return False
        errors.append(f"{name} must be true or false")
        return False

    q = (args.get("q") or "").strip()
    if len(q) > MAX_QUERY_LENGTH:
        errors.append(f"q must be at most {MAX_QUERY_LENGTH} characters")

    sort = (args.get("sort") or DEFAULT_SORT).strip()
    if sort not in SORT_OPTIONS:
        errors.append(f"sort must be one of: {', '.join(SORT_OPTIONS)}")

    lat = number("lat", lo=-90, hi=90)
    lng = number("lng", lo=-180, hi=180)
    if (lat is None) != (lng is None):
        errors.append("lat and lng must be provided together")
    has_location = lat is not None and lng is not None

    max_distance_km = number("max_distance_km", lo=0)
    if max_distance_km is not None and not has_location:
        errors.append("max_distance_km needs lat and lng")
    if sort == "nearest" and not has_location:
        errors.append("sort=nearest needs lat and lng")

    min_price = number("min_price", lo=0)
    max_price = number("max_price", lo=0)
    if min_price is not None and max_price is not None and min_price > max_price:
        errors.append("min_price must not be greater than max_price")

    min_discount = number("min_discount", lo=0, hi=100)
    expiring_within_hours = number("expiring_within_hours", lo=0, hi=24 * 30)

    listing_type = (args.get("listing_type") or "").strip().lower() or None
    if listing_type is not None and listing_type not in LISTING_TYPES:
        errors.append(f"listing_type must be one of: {', '.join(sorted(LISTING_TYPES))}")

    tags = csv("tags")
    for tag in tags:
        if not TAG_RE.match(tag):
            errors.append(f"invalid tag '{tag}' (use letters, digits and underscores)")

    page = number("page", kind=int, lo=1, hi=100_000) or 1
    page_size = number("page_size", kind=int, lo=1, hi=MAX_PAGE_SIZE) or DEFAULT_PAGE_SIZE
    include_sold_out = flag("include_sold_out")

    if errors:
        raise QueryError(errors)

    return {
        "q": q,
        "categories": csv("category"),
        "tags": tags,
        "listing_type": listing_type,
        "min_price": min_price,
        "max_price": max_price,
        "min_discount": min_discount,
        "expiring_within_hours": expiring_within_hours,
        "max_distance_km": max_distance_km,
        "lat": lat,
        "lng": lng,
        "has_location": has_location,
        "include_sold_out": include_sold_out,
        "sort": sort,
        "page": page,
        "page_size": page_size,
    }


def distance_sql(p: dict) -> str:
    return "haversine(:lat, :lng, b.lat, b.lng)" if p["has_location"] else "NULL"


def build_where(p: dict, now: datetime) -> tuple[str, dict]:
    where = ["l.expiry_at > :now"]  
    args: dict = {"now": to_iso(now)}

    if not p["include_sold_out"]:
        where.append("l.quantity > 0")

    for i, term in enumerate(p["q"].lower().split()[:MAX_SEARCH_TERMS]):
        args[f"q{i}"] = like_contains(term)
        where.append(
            f"(l.title LIKE :q{i} ESCAPE '\\' OR l.description LIKE :q{i} ESCAPE '\\' "
            f"OR l.category LIKE :q{i} ESCAPE '\\' OR b.name LIKE :q{i} ESCAPE '\\' "
            f"OR l.tags LIKE :q{i} ESCAPE '\\')"
        )

    if p["categories"]:
        names = []
        for i, category in enumerate(p["categories"]):
            args[f"cat{i}"] = category
            names.append(f":cat{i}")
        where.append(f"LOWER(l.category) IN ({', '.join(names)})")

    for i, tag in enumerate(p["tags"]): 
        args[f"tag{i}"] = like_contains(f",{tag},")
        where.append(f"l.tags LIKE :tag{i} ESCAPE '\\'")

    if p["listing_type"]:
        where.append("l.listing_type = :listing_type")
        args["listing_type"] = p["listing_type"]

    if p["min_price"] is not None:
        where.append("l.price_sen >= :min_price_sen")
        args["min_price_sen"] = rm_to_sen(p["min_price"])
    if p["max_price"] is not None:
        where.append("l.price_sen <= :max_price_sen")
        args["max_price_sen"] = rm_to_sen(p["max_price"])

    if p["min_discount"] is not None:
        where.append(f"{DISCOUNT_SQL} >= :min_discount")
        args["min_discount"] = p["min_discount"]

    if p["expiring_within_hours"] is not None:
        where.append("l.expiry_at <= :expiry_cutoff")
        args["expiry_cutoff"] = to_iso(now + timedelta(hours=p["expiring_within_hours"]))

    if p["has_location"]:
        args["lat"], args["lng"] = p["lat"], p["lng"]
        if p["max_distance_km"] is not None:
            where.append(f"{distance_sql(p)} <= :max_distance_km")
            args["max_distance_km"] = p["max_distance_km"]

    return " AND ".join(where), args


def serialize_listing(row: sqlite3.Row, now: datetime) -> dict:
    seconds_left = (from_iso(row["expiry_at"]) - now).total_seconds()
    distance = row["distance_km"]
    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "category": row["category"],
        "listing_type": row["listing_type"],
        "price": sen_to_rm(row["price_sen"]),
        "original_price": sen_to_rm(row["original_price_sen"]),
        "discount_percent": int(row["discount_percent"]),
        "quantity_left": row["quantity"],
        "expiry_at": row["expiry_at"],
        "expires_in_minutes": max(0, int(seconds_left // 60)),
        "pickup_start": row["pickup_start"],
        "pickup_end": row["pickup_end"],
        "tags": decode_tags(row["tags"]),
        "image_url": row["image_url"],
        "distance_km": None if distance is None else round(distance, 2),
        "business": {
            "id": row["business_id"],
            "name": row["business_name"],
            "address": row["business_address"],
            "lat": row["business_lat"],
            "lng": row["business_lng"],
        },
    }


SELECT_COLUMNS = f"""
    l.*,
    b.name AS business_name, b.address AS business_address,
    b.lat AS business_lat, b.lng AS business_lng,
    {DISCOUNT_SQL} AS discount_percent,
    {{distance}} AS distance_km
"""

def get_db() -> sqlite3.Connection:
    if "db" not in g:
        conn = sqlite3.connect(current_app.config["DB_PATH"])
        conn.row_factory = sqlite3.Row
        conn.create_function("haversine", 4, haversine_km, deterministic=True)
        g.db = conn
    return g.db


def init_db(path: str) -> None:
    conn = sqlite3.connect(path)
    try:
        conn.executescript(SCHEMA)
        conn.commit()
    finally:
        conn.close()


def create_app(db_path: str | None = None, *, now_fn=utc_now, seed: bool = True) -> Flask:
    app = Flask(__name__)
    app.json.sort_keys = False  # keep field order as written
    app.config["DB_PATH"] = db_path or os.environ.get("CATALOG_DB", "catalog.db")
    app.config["NOW_FN"] = now_fn
    app.config["CORS_ORIGIN"] = os.environ.get("CORS_ORIGIN", "*")

    init_db(app.config["DB_PATH"])
    if seed:
        from seed import seed_demo_data_if_empty

        seed_demo_data_if_empty(app.config["DB_PATH"], now_fn())

    @app.teardown_appcontext
    def close_db(_exc):
        conn = g.pop("db", None)
        if conn is not None:
            conn.close()

    @app.after_request
    def add_cors(response):
        response.headers["Access-Control-Allow-Origin"] = app.config["CORS_ORIGIN"]
        return response

    @app.errorhandler(QueryError)
    def bad_query(err: QueryError):
        return jsonify({"error": "invalid_query", "details": err.details}), 400

    @app.errorhandler(404)
    def not_found(_err):
        return jsonify({"error": "not_found"}), 404

    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok"})

    @app.get("/api/catalog")
    def catalog():
        p = parse_catalog_params(request.args)
        now = app.config["NOW_FN"]()
        where, args = build_where(p, now)
        db = get_db()

        total = db.execute(
            f"SELECT COUNT(*) FROM listings l JOIN businesses b ON b.id = l.business_id WHERE {where}",
            args,
        ).fetchone()[0]

        sql = (
            f"SELECT {SELECT_COLUMNS.format(distance=distance_sql(p))} "
            f"FROM listings l JOIN businesses b ON b.id = l.business_id "
            f"WHERE {where} "
            f"ORDER BY {SORT_OPTIONS[p['sort']]}, l.id ASC "
            f"LIMIT :limit OFFSET :offset"
        )
        rows = db.execute(
            sql, {**args, "limit": p["page_size"], "offset": (p["page"] - 1) * p["page_size"]}
        ).fetchall()

        total_pages = math.ceil(total / p["page_size"]) if total else 0
        return jsonify(
            {
                "items": [serialize_listing(r, now) for r in rows],
                "page": p["page"],
                "page_size": p["page_size"],
                "total": total,
                "total_pages": total_pages,
                "has_next": p["page"] < total_pages,
                "sort": p["sort"],
                "filters": {
                    "q": p["q"],
                    "category": p["categories"],
                    "tags": p["tags"],
                    "listing_type": p["listing_type"],
                    "min_price": p["min_price"],
                    "max_price": p["max_price"],
                    "min_discount": p["min_discount"],
                    "expiring_within_hours": p["expiring_within_hours"],
                    "max_distance_km": p["max_distance_km"],
                    "include_sold_out": p["include_sold_out"],
                },
            }
        )

    @app.get("/api/catalog/facets")
    def facets():
        now = app.config["NOW_FN"]()
        db = get_db()
        base = "FROM listings l WHERE l.expiry_at > :now AND l.quantity > 0"
        categories = db.execute(
            f"SELECT LOWER(l.category) AS name, COUNT(*) AS count {base} "
            f"GROUP BY LOWER(l.category) ORDER BY count DESC, name ASC",
            {"now": to_iso(now)},
        ).fetchall()
        tag_counts: dict[str, int] = {}
        for (text,) in db.execute(f"SELECT l.tags {base}", {"now": to_iso(now)}):
            for tag in decode_tags(text):
                tag_counts[tag] = tag_counts.get(tag, 0) + 1
        price = db.execute(
            f"SELECT MIN(l.price_sen), MAX(l.price_sen), MAX({DISCOUNT_SQL}) {base}",
            {"now": to_iso(now)},
        ).fetchone()
        return jsonify(
            {
                "categories": [{"name": r["name"], "count": r["count"]} for r in categories],
                "tags": [
                    {"name": name, "count": count}
                    for name, count in sorted(tag_counts.items(), key=lambda kv: (-kv[1], kv[0]))
                ],
                "min_price": None if price[0] is None else sen_to_rm(price[0]),
                "max_price": None if price[1] is None else sen_to_rm(price[1]),
                "max_discount_percent": price[2] or 0,
                "sort_options": list(SORT_OPTIONS),
            }
        )

    @app.get("/api/catalog/<int:listing_id>")
    def listing_detail(listing_id: int):
        p = parse_catalog_params(request.args)
        now = app.config["NOW_FN"]()
        args: dict = {"id": listing_id, "now": to_iso(now)}
        if p["has_location"]:
            args["lat"], args["lng"] = p["lat"], p["lng"]
        row = (
            get_db()
            .execute(
                f"SELECT {SELECT_COLUMNS.format(distance=distance_sql(p))} "
                f"FROM listings l JOIN businesses b ON b.id = l.business_id "
                f"WHERE l.id = :id AND l.expiry_at > :now",
                args,
            )
            .fetchone()
        )
        if row is None:
            return jsonify({"error": "not_found"}), 404
        return jsonify(serialize_listing(row, now))

    return app


if __name__ == "__main__":
    create_app().run(host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
