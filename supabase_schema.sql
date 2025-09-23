-- Full Supabase schema and seed data for RevPick
-- Paste this whole file into Supabase SQL editor and run

-- =========================
-- Extensions
-- =========================
create extension if not exists pgcrypto;

-- =========================
-- Tables
-- =========================

-- Categories
create table if not exists public.categories (
	category_id uuid primary key default gen_random_uuid(),
	name text not null unique,
	description text,
	created_at timestamptz not null default now()
);

-- Products/Bikes
-- EV support via is_electric + power_kw; ICE uses engine_cc > 0
create table if not exists public.products (
	prod_id uuid primary key default gen_random_uuid(),
	name text not null,
	engine_cc integer check (engine_cc is null or engine_cc > 0),
	price numeric(12,2) not null check (price >= 0),
	stock integer not null default 0 check (stock >= 0),
	category_id uuid references public.categories(category_id) on update cascade on delete set null,
	brand text not null,
	is_electric boolean not null default false,
	power_kw numeric(6,2),
	created_at timestamptz not null default now(),
	constraint products_ice_or_ev check (
		(is_electric = false and engine_cc is not null and engine_cc > 0)
		or
		(is_electric = true and power_kw is not null)
	)
);

-- Customers
create table if not exists public.customers (
	cust_id uuid primary key default gen_random_uuid(),
	name text not null,
	email text unique,
	phone text,
	city text,
	created_at timestamptz not null default now()
);

-- Stores/Dealers
create table if not exists public.stores (
	store_id uuid primary key default gen_random_uuid(),
	name text not null,
	location text,
	contact text,
	created_at timestamptz not null default now()
);

-- Suggestions (history of recommended bikes for a customer)
create table if not exists public.suggestions (
	suggestion_id uuid primary key default gen_random_uuid(),
	cust_id uuid not null references public.customers(cust_id) on update cascade on delete cascade,
	prod_id uuid not null references public.products(prod_id) on update cascade on delete cascade,
	date_requested timestamptz not null default now()
);

-- =========================
-- Indexes
-- =========================
create index if not exists idx_products_category_id on public.products(category_id);
create index if not exists idx_products_brand on public.products(brand);
create index if not exists idx_products_price on public.products(price);
create index if not exists idx_products_is_electric on public.products(is_electric);
create index if not exists idx_customers_city on public.customers(city);
create index if not exists idx_suggestions_cust on public.suggestions(cust_id);
create index if not exists idx_suggestions_prod on public.suggestions(prod_id);

-- =========================
-- Seed: Categories
-- =========================
insert into public.categories (name, description) values
  ('Commuter', 'Everyday city riding and fuel efficiency'),
  ('Cruiser', 'Relaxed ergonomics, low seat height'),
  ('Sport', 'Performance and aggressive posture'),
  ('Adventure', 'On/off-road touring and long travel suspension'),
  ('Touring', 'Long-distance comfort and luggage'),
  ('Electric', 'Electric powertrain'),
  ('Scooter', 'Step-through, CVT automatic'),
  ('Naked', 'Minimal fairing, upright ergonomics'),
  ('Retro', 'Classic styling with modern tech')
on conflict (name) do nothing;

-- Helper CTE for category ids
with cat as (
	select category_id, name from public.categories
)
-- =========================
-- Seed: Many Bikes (prices in INR; adjust as needed)
insert into public.products
(name, engine_cc, price, stock, category_id, brand, is_electric, power_kw)
values
-- Commuter
('Honda Shine 125', 124, 79000, 30, (select category_id from cat where name='Commuter'), 'Honda', false, null),
('Hero Splendor Plus', 97, 72000, 60, (select category_id from cat where name='Commuter'), 'Hero', false, null),
('Bajaj Pulsar 150', 149, 115000, 25, (select category_id from cat where name='Commuter'), 'Bajaj', false, null),
('TVS Radeon', 109, 75000, 30, (select category_id from cat where name='Commuter'), 'TVS', false, null),
('Yamaha FZ-S Fi', 149, 128000, 18, (select category_id from cat where name='Commuter'), 'Yamaha', false, null),
('Honda Unicorn', 162, 125000, 16, (select category_id from cat where name='Commuter'), 'Honda', false, null),

-- Cruiser
('Royal Enfield Meteor 350', 349, 220000, 20, (select category_id from cat where name='Cruiser'), 'Royal Enfield', false, null),
('Bajaj Avenger 220 Cruise', 220, 150000, 15, (select category_id from cat where name='Cruiser'), 'Bajaj', false, null),
('Royal Enfield Super Meteor 650', 648, 350000, 6, (select category_id from cat where name='Cruiser'), 'Royal Enfield', false, null),
('Honda Hness CB350', 348, 215000, 10, (select category_id from cat where name='Cruiser'), 'Honda', false, null),

-- Sport
('Yamaha R15 V4', 155, 190000, 25, (select category_id from cat where name='Sport'), 'Yamaha', false, null),
('KTM RC 390', 373, 380000, 10, (select category_id from cat where name='Sport'), 'KTM', false, null),
('Kawasaki Ninja 300', 296, 350000, 8, (select category_id from cat where name='Sport'), 'Kawasaki', false, null),
('Kawasaki Ninja 650', 649, 780000, 5, (select category_id from cat where name='Sport'), 'Kawasaki', false, null),
('Aprilia RS 457', 457, 420000, 7, (select category_id from cat where name='Sport'), 'Aprilia', false, null),
('Suzuki GSX-S750', 749, 950000, 2, (select category_id from cat where name='Sport'), 'Suzuki', false, null),

-- Adventure
('BMW F 700 GS', 700, 1500000, 4, (select category_id from cat where name='Adventure'), 'BMW', false, null),
('BMW G 310 GS', 313, 350000, 8, (select category_id from cat where name='Adventure'), 'BMW', false, null),
('Royal Enfield Himalayan 450', 452, 300000, 15, (select category_id from cat where name='Adventure'), 'Royal Enfield', false, null),
('KTM 390 Adventure', 373, 380000, 10, (select category_id from cat where name='Adventure'), 'KTM', false, null),
('Triumph Tiger Sport 660', 660, 950000, 3, (select category_id from cat where name='Adventure'), 'Triumph', false, null),
('Honda CB500X', 471, 700000, 4, (select category_id from cat where name='Adventure'), 'Honda', false, null),

-- Touring
('Honda Gold Wing', 1833, 3000000, 1, (select category_id from cat where name='Touring'), 'Honda', false, null),
('Kawasaki Versys 650', 649, 900000, 4, (select category_id from cat where name='Touring'), 'Kawasaki', false, null),
('Suzuki V-Strom 650XT', 645, 880000, 3, (select category_id from cat where name='Touring'), 'Suzuki', false, null),
('BMW R 1250 RT', 1254, 3200000, 1, (select category_id from cat where name='Touring'), 'BMW', false, null),

-- Electric (EVs: is_electric=true, power_kw set, engine_cc null)
('Revolt RV400', null, 145000, 20, (select category_id from cat where name='Electric'), 'Revolt', true, 3.00),
('Ultraviolette F77', null, 380000, 6, (select category_id from cat where name='Electric'), 'Ultraviolette', true, 25.00),
('Ather 450X', null, 170000, 25, (select category_id from cat where name='Electric'), 'Ather', true, 6.40),
('Ola S1 Pro', null, 135000, 30, (select category_id from cat where name='Electric'), 'Ola', true, 8.50),
('Tork Kratos R', null, 200000, 8, (select category_id from cat where name='Electric'), 'Tork', true, 9.00),

-- Scooter
('Honda Activa 6G', 109, 90000, 60, (select category_id from cat where name='Scooter'), 'Honda', false, null),
('TVS Ntorq 125', 124, 105000, 35, (select category_id from cat where name='Scooter'), 'TVS', false, null),
('Suzuki Access 125', 124, 100000, 28, (select category_id from cat where name='Scooter'), 'Suzuki', false, null),
('Yamaha Aerox 155', 155, 145000, 15, (select category_id from cat where name='Scooter'), 'Yamaha', false, null),

-- Naked
('Yamaha MT-15 V2', 155, 195000, 30, (select category_id from cat where name='Naked'), 'Yamaha', false, null),
('KTM 390 Duke', 399, 330000, 12, (select category_id from cat where name='Naked'), 'KTM', false, null),
('Kawasaki Z650', 649, 720000, 6, (select category_id from cat where name='Naked'), 'Kawasaki', false, null),
('Triumph Trident 660', 660, 850000, 4, (select category_id from cat where name='Naked'), 'Triumph', false, null),
('Honda CB300R', 286, 280000, 10, (select category_id from cat where name='Naked'), 'Honda', false, null),

-- Retro
('Royal Enfield Classic 350', 349, 230000, 25, (select category_id from cat where name='Retro'), 'Royal Enfield', false, null),
('Jawa 42', 293, 205000, 15, (select category_id from cat where name='Retro'), 'Jawa', false, null),
('Benelli Imperiale 400', 374, 230000, 8, (select category_id from cat where name='Retro'), 'Benelli', false, null),
('Triumph Bonneville T120', 1200, 1200000, 2, (select category_id from cat where name='Retro'), 'Triumph', false, null),
('Honda H''ness CB350', 348, 215000, 10, (select category_id from cat where name='Retro'), 'Honda', false, null)
;
create extension if not exists pgcrypto;

-- Categories
create table if not exists public.categories (
	category_id uuid primary key default gen_random_uuid(),
	name text not null unique,
	description text,
	created_at timestamptz not null default now()
);

-- Products/Bikes
create table if not exists public.products (
	prod_id uuid primary key default gen_random_uuid(),
	name text not null,
	engine_cc integer not null check (engine_cc > 0),
	price numeric(12,2) not null check (price >= 0),
	stock integer not null default 0 check (stock >= 0),
	category_id uuid references public.categories(category_id) on update cascade on delete set null,
	brand text not null,
	created_at timestamptz not null default now()
);

-- Customers
create table if not exists public.customers (
	cust_id uuid primary key default gen_random_uuid(),
	name text not null,
	email text unique,
	phone text,
	city text,
	created_at timestamptz not null default now()
);

-- Stores/Dealers
create table if not exists public.stores (
	store_id uuid primary key default gen_random_uuid(),
	name text not null,
	location text,
	contact text,
	created_at timestamptz not null default now()
);

-- Suggestions (history of recommended bikes for a customer)
create table if not exists public.suggestions (
	suggestion_id uuid primary key default gen_random_uuid(),
	cust_id uuid not null references public.customers(cust_id) on update cascade on delete cascade,
	prod_id uuid not null references public.products(prod_id) on update cascade on delete cascade,
	date_requested timestamptz not null default now()
);

-- Indexes
create index if not exists idx_products_category_id on public.products(category_id);
create index if not exists idx_products_brand on public.products(brand);
create index if not exists idx_products_price on public.products(price);
create index if not exists idx_customers_city on public.customers(city);
create index if not exists idx_suggestions_cust on public.suggestions(cust_id);
create index if not exists idx_suggestions_prod on public.suggestions(prod_id);
