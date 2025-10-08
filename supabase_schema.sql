-- =========================
-- Drop existing tables
-- =========================
DROP TABLE IF EXISTS public.suggestions;
DROP TABLE IF EXISTS public.stores;
DROP TABLE IF EXISTS public.customers;
DROP TABLE IF EXISTS public.products;
DROP TABLE IF EXISTS public.categories;

-- =========================
-- Enable required extension
-- =========================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================
-- Tables
-- =========================

-- Categories
CREATE TABLE public.categories (
  category_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Products/Bikes
CREATE TABLE public.products (
  prod_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  engine_cc INTEGER CHECK (engine_cc IS NULL OR engine_cc > 0),
  price NUMERIC(12,2) NOT NULL CHECK (price >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  category_id UUID REFERENCES public.categories(category_id) ON UPDATE CASCADE ON DELETE SET NULL,
  brand TEXT NOT NULL,
  is_electric BOOLEAN NOT NULL DEFAULT FALSE,
  power_kw NUMERIC(6,2),
  bhp NUMERIC(6,2),
  torque_nm NUMERIC(7,2),
  mileage_kmpl NUMERIC(6,2),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT products_ice_or_ev CHECK (
    (is_electric = FALSE AND engine_cc IS NOT NULL AND engine_cc > 0)
    OR
    (is_electric = TRUE AND power_kw IS NOT NULL)
  )
);

-- Customers
CREATE TABLE public.customers (
  cust_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  email TEXT UNIQUE,
  phone TEXT,
  city TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Stores/Dealers
CREATE TABLE public.stores (
  store_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  location TEXT,
  contact TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Suggestions
CREATE TABLE public.suggestions (
  suggestion_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cust_id UUID NOT NULL REFERENCES public.customers(cust_id) ON UPDATE CASCADE ON DELETE CASCADE,
  prod_id UUID NOT NULL REFERENCES public.products(prod_id) ON UPDATE CASCADE ON DELETE CASCADE,
  date_requested TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- =========================
-- Indexes
-- =========================
CREATE INDEX idx_products_category_id ON public.products(category_id);
CREATE INDEX idx_products_brand ON public.products(brand);
CREATE INDEX idx_products_price ON public.products(price);
CREATE INDEX idx_products_is_electric ON public.products(is_electric);
CREATE INDEX idx_products_cc ON public.products(engine_cc);
CREATE INDEX idx_customers_city ON public.customers(city);
CREATE INDEX idx_suggestions_cust ON public.suggestions(cust_id);
CREATE INDEX idx_suggestions_prod ON public.suggestions(prod_id);

-- =========================
-- Seed: Categories
-- =========================
INSERT INTO public.categories (name, description) VALUES
  ('Commuter', 'Everyday city riding and fuel efficiency'),
  ('Cruiser', 'Relaxed ergonomics, low seat height'),
  ('Sport', 'Performance and aggressive posture'),
  ('Adventure', 'On/off-road touring and long travel suspension'),
  ('Touring', 'Long-distance comfort and luggage'),
  ('Electric', 'Electric powertrain'),
  ('Scooter', 'Step-through, CVT automatic'),
  ('Naked', 'Minimal fairing, upright ergonomics'),
  ('Retro', 'Classic styling with modern tech'),
  ('Supersport', 'High-performance sports bikes')
ON CONFLICT (name) DO NOTHING;

-- =========================
-- Seed: Products/Bikes (100 unique bikes)
-- =========================
WITH cat AS (SELECT category_id, name FROM public.categories)
INSERT INTO public.products
(name, engine_cc, price, stock, category_id, brand, is_electric, power_kw, bhp, torque_nm, mileage_kmpl)
VALUES
-- Commuter (10 bikes)
('Honda Shine 125', 124, 79000, 30, (SELECT category_id FROM cat WHERE name='Commuter'), 'Honda', FALSE, NULL, 10.59, 11.00, 55.00),
('Hero Splendor Plus', 97, 72000, 60, (SELECT category_id FROM cat WHERE name='Commuter'), 'Hero', FALSE, NULL, 7.91, 8.05, 65.00),
('Bajaj Pulsar 150', 149, 115000, 25, (SELECT category_id FROM cat WHERE name='Commuter'), 'Bajaj', FALSE, NULL, 13.80, 13.25, 45.00),
('TVS Radeon', 109, 75000, 30, (SELECT category_id FROM cat WHERE name='Commuter'), 'TVS', FALSE, NULL, 8.40, 8.70, 60.00),
('Yamaha FZ-S Fi', 149, 128000, 18, (SELECT category_id FROM cat WHERE name='Commuter'), 'Yamaha', FALSE, NULL, 12.40, 13.30, 48.00),
('Honda Unicorn', 162, 125000, 16, (SELECT category_id FROM cat WHERE name='Commuter'), 'Honda', FALSE, NULL, 12.90, 14.00, 50.00),
('Suzuki Gixxer 155', 155, 135000, 20, (SELECT category_id FROM cat WHERE name='Commuter'), 'Suzuki', FALSE, NULL, 13.00, 14.00, 50.00),
('Bajaj Platina 110', 112, 65000, 25, (SELECT category_id FROM cat WHERE name='Commuter'), 'Bajaj', FALSE, NULL, 8.0, 9.0, 65.00),
('Hero Passion Pro', 110, 70000, 40, (SELECT category_id FROM cat WHERE name='Commuter'), 'Hero', FALSE, NULL, 8.3, 8.5, 63.00),
('TVS Star City Plus', 109, 73000, 30, (SELECT category_id FROM cat WHERE name='Commuter'), 'TVS', FALSE, NULL, 8.5, 9.0, 60.00),

-- Cruiser (8 bikes)
('Royal Enfield Meteor 350', 349, 220000, 20, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Royal Enfield', FALSE, NULL, 20.20, 27.00, 35.00),
('Bajaj Avenger 220 Cruise', 220, 150000, 15, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Bajaj', FALSE, NULL, 19.00, 17.55, 40.00),
('Royal Enfield Super Meteor 650', 648, 350000, 6, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Royal Enfield', FALSE, NULL, 46.00, 52.30, 25.00),
('Honda Hness CB350', 348, 215000, 10, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Honda', FALSE, NULL, 20.78, 30.00, 35.00),
('KTM 390 Cruiser', 373, 380000, 8, (SELECT category_id FROM cat WHERE name='Cruiser'), 'KTM', FALSE, NULL, 35.00, 30.00, 30.00),
('Yamaha Bolt R-Spec', 942, 800000, 5, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Yamaha', FALSE, NULL, 54.00, 80.00, 25.00),
('Suzuki Intruder 150', 155, 170000, 12, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Suzuki', FALSE, NULL, 14.5, 14.0, 45.00),
('Kawasaki Vulcan S', 649, 750000, 4, (SELECT category_id FROM cat WHERE name='Cruiser'), 'Kawasaki', FALSE, NULL, 61.0, 64.0, 22.0),

-- Sport (12 bikes)
('Yamaha R15 V4', 155, 190000, 25, (SELECT category_id FROM cat WHERE name='Sport'), 'Yamaha', FALSE, NULL, 18.40, 14.20, 40.00),
('KTM RC 390', 373, 380000, 10, (SELECT category_id FROM cat WHERE name='Sport'), 'KTM', FALSE, NULL, 43.50, 37.00, 28.00),
('Kawasaki Ninja 300', 296, 350000, 8, (SELECT category_id FROM cat WHERE name='Sport'), 'Kawasaki', FALSE, NULL, 39.00, 27.00, 26.00),
('Kawasaki Ninja 650', 649, 780000, 5, (SELECT category_id FROM cat WHERE name='Sport'), 'Kawasaki', FALSE, NULL, 67.00, 64.00, 22.00),
('Aprilia RS 457', 457, 420000, 7, (SELECT category_id FROM cat WHERE name='Sport'), 'Aprilia', FALSE, NULL, 47.60, 43.50, 28.00),
('Suzuki GSX-R1000', 999, 2000000, 3, (SELECT category_id FROM cat WHERE name='Sport'), 'Suzuki', FALSE, NULL, 199.0, 112.0, 15.0),
('Ducati Panigale V2', 955, 1800000, 2, (SELECT category_id FROM cat WHERE name='Sport'), 'Ducati', FALSE, NULL, 155.0, 104.0, 14.0),
('Yamaha R7', 689, 950000, 6, (SELECT category_id FROM cat WHERE name='Sport'), 'Yamaha', FALSE, NULL, 73.4, 67.0, 21.0),
('KTM RC 200', 199, 250000, 15, (SELECT category_id FROM cat WHERE name='Sport'), 'KTM', FALSE, NULL, 25.0, 24.0, 35.0),
('Honda CBR500R', 471, 650000, 4, (SELECT category_id FROM cat WHERE name='Sport'), 'Honda', FALSE, NULL, 47.6, 43.0, 28.0),
('Kawasaki ZX-6R', 636, 1200000, 3, (SELECT category_id FROM cat WHERE name='Sport'), 'Kawasaki', FALSE, NULL, 127.0, 70.0, 17.0),
('Ducati SuperSport 950', 937, 1600000, 2, (SELECT category_id FROM cat WHERE name='Sport'), 'Ducati', FALSE, NULL, 110.0, 96.0, 15.0),

-- Adventure (10 bikes)
('BMW F 700 GS', 700, 1500000, 4, (SELECT category_id FROM cat WHERE name='Adventure'), 'BMW', FALSE, NULL, 75.00, 77.00, 20.00),
('BMW G 310 GS', 313, 350000, 8, (SELECT category_id FROM cat WHERE name='Adventure'), 'BMW', FALSE, NULL, 33.50, 28.00, 30.00),
('Royal Enfield Himalayan 450', 452, 300000, 15, (SELECT category_id FROM cat WHERE name='Adventure'), 'Royal Enfield', FALSE, NULL, 40.00, 40.00, 28.00),
('KTM 390 Adventure', 373, 380000, 10, (SELECT category_id FROM cat WHERE name='Adventure'), 'KTM', FALSE, NULL, 43.50, 37.00, 28.00),
('Triumph Tiger Sport 660', 660, 950000, 3, (SELECT category_id FROM cat WHERE name='Adventure'), 'Triumph', FALSE, NULL, 80.00, 64.00, 22.00),
('Honda CB500X', 471, 700000, 4, (SELECT category_id FROM cat WHERE name='Adventure'), 'Honda', FALSE, NULL, 47.60, 43.00, 28.00),
('BMW R 1250 GS', 1254, 3500000, 2, (SELECT category_id FROM cat WHERE name='Adventure'), 'BMW', FALSE, NULL, 136.00, 143.00, 18.00),
('Triumph Tiger 1200', 1215, 2500000, 2, (SELECT category_id FROM cat WHERE name='Adventure'), 'Triumph', FALSE, NULL, 141.00, 125.00, 16.00),
('Ducati Multistrada V4', 1158, 2700000, 2, (SELECT category_id FROM cat WHERE name='Adventure'), 'Ducati', FALSE, NULL, 170.00, 125.00, 20.00),
('KTM 1290 Super Adventure S', 1301, 3600000, 2, (SELECT category_id FROM cat WHERE name='Adventure'), 'KTM', FALSE, NULL, 160.00, 138.00, 19.00),

-- Touring (6 bikes)
('Honda Gold Wing', 1833, 3000000, 1, (SELECT category_id FROM cat WHERE name='Touring'), 'Honda', FALSE, NULL, 125.00, 170.00, 15.00),
('Kawasaki Versys 650', 649, 900000, 4, (SELECT category_id FROM cat WHERE name='Touring'), 'Kawasaki', FALSE, NULL, 66.00, 61.00, 24.00),
('Suzuki V-Strom 650XT', 645, 880000, 3, (SELECT category_id FROM cat WHERE name='Touring'), 'Suzuki', FALSE, NULL, 70.00, 62.00, 24.00),
('BMW R 1250 RT', 1254, 3200000, 1, (SELECT category_id FROM cat WHERE name='Touring'), 'BMW', FALSE, NULL, 136.00, 143.00, 18.00),
('Triumph Trophy 1215', 1215, 2700000, 2, (SELECT category_id FROM cat WHERE name='Touring'), 'Triumph', FALSE, NULL, 141.00, 125.00, 17.00),
('Ducati Multistrada V4 Touring', 1158, 2900000, 1, (SELECT category_id FROM cat WHERE name='Touring'), 'Ducati', FALSE, NULL, 170.00, 125.00, 18.00),

-- Electric (6 bikes)
('Revolt RV400', NULL, 145000, 20, (SELECT category_id FROM cat WHERE name='Electric'), 'Revolt', TRUE, 3.00, NULL, NULL, 6.00),
('Ultraviolette F77', NULL, 380000, 6, (SELECT category_id FROM cat WHERE name='Electric'), 'Ultraviolette', TRUE, 25.00, NULL, NULL, 8.50),
('Ather 450X', NULL, 170000, 25, (SELECT category_id FROM cat WHERE name='Electric'), 'Ather', TRUE, 6.40, NULL, NULL, 7.00),
('Ola S1 Pro', NULL, 135000, 30, (SELECT category_id FROM cat WHERE name='Electric'), 'Ola', TRUE, 8.50, NULL, NULL, 7.50),
('Tork Kratos R', NULL, 200000, 8, (SELECT category_id FROM cat WHERE name='Electric'), 'Tork', TRUE, 9.00, NULL, NULL, 7.00),
('Revolt RV300', NULL, 120000, 15, (SELECT category_id FROM cat WHERE name='Electric'), 'Revolt', TRUE, 2.50, NULL, NULL, 5.50),

-- Scooter (6 bikes)
('Honda Activa 6G', 109, 90000, 60, (SELECT category_id FROM cat WHERE name='Scooter'), 'Honda', FALSE, NULL, 7.68, 8.84, 50.00),
('TVS Ntorq 125', 124, 105000, 35, (SELECT category_id FROM cat WHERE name='Scooter'), 'TVS', FALSE, NULL, 9.25, 10.50, 45.00),
('Suzuki Access 125', 124, 100000, 28, (SELECT category_id FROM cat WHERE name='Scooter'), 'Suzuki', FALSE, NULL, 8.70, 10.00, 48.00),
('Yamaha Aerox 155', 155, 145000, 15, (SELECT category_id FROM cat WHERE name='Scooter'), 'Yamaha', FALSE, NULL, 14.79, 13.90, 40.00),
('Vespa SXL 150', 150, 160000, 10, (SELECT category_id FROM cat WHERE name='Scooter'), 'Vespa', FALSE, NULL, 11.0, 10.5, 38.00),
('TVS Jupiter 125', 124, 95000, 20, (SELECT category_id FROM cat WHERE name='Scooter'), 'TVS', FALSE, NULL, 8.5, 9.0, 50.00),

-- Naked (10 bikes)
('Yamaha MT-15 V2', 155, 195000, 30, (SELECT category_id FROM cat WHERE name='Naked'), 'Yamaha', FALSE, NULL, 18.40, 14.10, 40.00),
('KTM 390 Duke', 399, 330000, 12, (SELECT category_id FROM cat WHERE name='Naked'), 'KTM', FALSE, NULL, 45.00, 39.00, 27.00),
('Kawasaki Z650', 649, 720000, 6, (SELECT category_id FROM cat WHERE name='Naked'), 'Kawasaki', FALSE, NULL, 67.00, 64.00, 22.00),
('Triumph Trident 660', 660, 850000, 4, (SELECT category_id FROM cat WHERE name='Naked'), 'Triumph', FALSE, NULL, 80.00, 64.00, 21.00),
('Honda CB300R', 286, 280000, 10, (SELECT category_id FROM cat WHERE name='Naked'), 'Honda', FALSE, NULL, 30.45, 27.50, 31.00),
('Ducati Monster 1200', 1198, 1800000, 2, (SELECT category_id FROM cat WHERE name='Naked'), 'Ducati', FALSE, NULL, 147.00, 124.00, 16.00),
('KTM 1290 Super Duke GT', 1301, 2100000, 1, (SELECT category_id FROM cat WHERE name='Naked'), 'KTM', FALSE, NULL, 177.00, 141.00, 17.00),
('Yamaha MT-10 SP', 998, 1600000, 2, (SELECT category_id FROM cat WHERE name='Naked'), 'Yamaha', FALSE, NULL, 160.00, 111.00, 15.50),
('KTM 200 Duke', 199, 240000, 10, (SELECT category_id FROM cat WHERE name='Naked'), 'KTM', FALSE, NULL, 25.0, 24.0, 33.0),
('Honda CB500F', 471, 650000, 6, (SELECT category_id FROM cat WHERE name='Naked'), 'Honda', FALSE, NULL, 47.6, 43.0, 28.0),

-- Retro (6 bikes)
('Royal Enfield Classic 350', 349, 230000, 25, (SELECT category_id FROM cat WHERE name='Retro'), 'Royal Enfield', FALSE, NULL, 20.20, 27.00, 35.00),
('Jawa 42', 293, 205000, 15, (SELECT category_id FROM cat WHERE name='Retro'), 'Jawa', FALSE, NULL, 27.30, 27.00, 34.00),
('Benelli Imperiale 400', 374, 230000, 8, (SELECT category_id FROM cat WHERE name='Retro'), 'Benelli', FALSE, NULL, 21.00, 29.00, 32.00),
('Triumph Bonneville T120', 1200, 1200000, 2, (SELECT category_id FROM cat WHERE name='Retro'), 'Triumph', FALSE, NULL, 80.00, 105.00, 18.00),
('Honda Hness CB350 Retro', 348, 215000, 10, (SELECT category_id FROM cat WHERE name='Retro'), 'Honda', FALSE, NULL, 20.78, 30.00, 35.00),
('Royal Enfield Bullet 500', 499, 240000, 12, (SELECT category_id FROM cat WHERE name='Retro'), 'Royal Enfield', FALSE, NULL, 27.0, 41.0, 32.0),

-- Supersport (11 bikes)
('KTM 1290 Super Duke R', 1301, 2000000, 3, (SELECT category_id FROM cat WHERE name='Supersport'), 'KTM', FALSE, NULL, 177.00, 141.00, 18.00),
('Ducati Panigale V4', 1103, 2500000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Ducati', FALSE, NULL, 214.00, 124.00, 16.00),
('Ducati Streetfighter V4', 1103, 2400000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Ducati', FALSE, NULL, 208.00, 123.00, 15.50),
('Kawasaki Ninja ZX-10R', 998, 2200000, 4, (SELECT category_id FROM cat WHERE name='Supersport'), 'Kawasaki', FALSE, NULL, 203.00, 114.00, 15.00),
('BMW S 1000 RR', 999, 2500000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'BMW', FALSE, NULL, 212.00, 113.00, 14.50),
('Ducati Panigale V4 S', 1103, 2800000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Ducati', FALSE, NULL, 221.00, 124.00, 15.50),
('Ducati Panigale V4 SP', 1103, 3200000, 1, (SELECT category_id FROM cat WHERE name='Supersport'), 'Ducati', FALSE, NULL, 234.00, 125.00, 15.00),
('Aprilia RSV4 1100 Factory', 1078, 2500000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Aprilia', FALSE, NULL, 217.00, 122.00, 14.50),
('Yamaha R1M', 998, 2200000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Yamaha', FALSE, NULL, 200.00, 112.00, 14.50),
('Kawasaki Ninja ZX-6R', 636, 1200000, 3, (SELECT category_id FROM cat WHERE name='Supersport'), 'Kawasaki', FALSE, NULL, 127.00, 70.00, 17.00),
('Suzuki GSX-R750', 749, 1500000, 2, (SELECT category_id FROM cat WHERE name='Supersport'), 'Suzuki', FALSE, NULL, 145.0, 95.0, 15.0);
