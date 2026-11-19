'use strict';

const { toIso, rmToSen, encodeTags } = require('./catalog');

const DEFAULT_LAT = 3.139;
const DEFAULT_LNG = 101.6869;

//NAMA KEDAI, ALAMAT, BERAPA JAUH DARI UTARA SELATAN, BERAPA JAUH DARI TIMUR BARAT
const BUSINESSES = [
  ['Aeon', 'Skudai', 0.004, 0.003],
  ['Jaya Grocer', 'Pulai', 0.02, -0.01],
  ['Econsave', 'Mutiara Rini', -0.03, 0.02],
  ['Mydin', 'Iskandar Puteri', 0.06, 0.05],
];

// [business #, title, description, category, price RM, original RM, qty, hours until expiry, tags, listing type, pickup start +h, pickup end +h]
const LISTINGS = [
  [1, 'Bakery Bread Assortment', 'Loaves and buns from the in-store bakery, baked today.', 'bakery', 5.0, 15.0, 12, 3, ['halal', 'vegetarian'], 'sale', 1, 3],
  [1, 'Deli Bento Set', 'Ready-to-eat chicken rice bento from the deli counter.', 'meals', 8.0, 18.0, 6, 4, ['halal'], 'sale', 1, 4],
  [2, 'Organic Salad Pack', 'Washed organic greens, cherry tomatoes and dressing.', 'produce', 4.5, 9.0, 6, 8, ['halal', 'vegan', 'vegetarian'], 'sale', 3, 8],
  [2, 'Imported Fruit Basket', 'Apples, oranges and grapes nearing peak ripeness.', 'produce', 9.0, 24.0, 5, 20, ['halal', 'vegan', 'vegetarian'], 'sale', 6, 20],
  [2, 'Cold-pressed Juice Trio', 'Orange, green detox and carrot-ginger juices.', 'beverages', 8.0, 21.0, 9, 40, ['halal', 'vegan', 'vegetarian'], 'sale', 8, 40],
  [3, 'Mixed Vegetable Bundle', 'Kangkung, bayam, carrots and long beans, ready for cooking.', 'produce', 3.0, 8.0, 15, 10, ['halal', 'vegan', 'vegetarian'], 'sale', 2, 10],
  [3, 'Fresh Milk & Yoghurt Pack', 'Two cartons of fresh milk and four plain yoghurt cups.', 'dairy', 6.0, 16.0, 10, 14, ['halal', 'vegetarian'], 'sale', 4, 14],
  [3, 'Day-old Bread Loaves', 'Ten sandwich loaves, free for registered charities.', 'bakery', 0.0, 20.0, 25, 6, ['halal', 'vegetarian'], 'donation', 2, 6],
  [4, 'Frozen Nuggets & Sausage Pack', 'Chicken nuggets and sausages, best before in 3 days.', 'frozen', 9.0, 22.0, 8, 72, ['halal'], 'sale', 3, 72],
  [4, 'Kuih Muih Box', 'Assorted traditional kuih from the food counter, 12 pieces.', 'desserts', 5.0, 12.0, 14, 5, ['halal', 'vegetarian'], 'sale', 1, 5],
  [4, 'Instant Noodle Variety Carton', 'Mixed flavours, packaging slightly damaged but sealed.', 'pantry', 7.0, 18.0, 10, 48, ['halal'], 'sale', 4, 48],
];

const hoursFrom = (now, h) => toIso(new Date(now.getTime() + h * 3600 * 1000));

function seedDemoDataIfEmpty(db, now) {
  if (db.prepare('SELECT COUNT(*) AS n FROM listings').get().n) return;
  const lat0 = Number(process.env.SEED_LAT || DEFAULT_LAT);
  const lng0 = Number(process.env.SEED_LNG || DEFAULT_LNG);

  const addBusiness = db.prepare(
    'INSERT INTO businesses (id, name, address, lat, lng) VALUES (?, ?, ?, ?, ?)',
  );
  const addListing = db.prepare(
    `INSERT INTO listings (business_id, title, description, category, price_sen, original_price_sen,
       quantity, expiry_at, pickup_start, pickup_end, tags, listing_type, image_url, created_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, ?)`,
  );

  db.exec('BEGIN');
  try {
    BUSINESSES.forEach(([name, address, dLat, dLng], i) => {
      addBusiness.run(i + 1, name, address, lat0 + dLat, lng0 + dLng);
    });
    LISTINGS.forEach((row, n) => {
      const [biz, title, desc, cat, price, orig, qty, hours, tags, type, pStart, pEnd] = row;
      addListing.run(
        biz, title, desc, cat, rmToSen(price), rmToSen(orig), qty,
        hoursFrom(now, hours), hoursFrom(now, pStart), hoursFrom(now, pEnd),
        encodeTags(tags), type, hoursFrom(now, -n / 6), // 10 minutes apart
      );
    });
    db.exec('COMMIT');
  } catch (err) {
    db.exec('ROLLBACK');
    throw err;
  }
}

module.exports = { seedDemoDataIfEmpty };
