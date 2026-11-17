-- FACET appliance store: products table for the Supabase-Flutter activity.
-- Run this once in Supabase Dashboard -> SQL Editor, then run seed.sql.

create table if not exists public.products (
  id          bigint generated always as identity primary key,
  name        text          not null check (char_length(name) between 1 and 80),
  description text          not null default '',
  price       numeric(10,2) not null check (price >= 0),
  category    text          not null check (char_length(category) between 1 and 40),
  stock       integer       not null default 0 check (stock >= 0),
  -- Which 3D appliance model the app draws for this product.
  model       text          not null default 'fridge'
              check (model in ('fridge', 'washer', 'microwave', 'tv', 'fan', 'aircon',
                               'rice_cooker', 'blender', 'air_fryer', 'toaster', 'kettle',
                               'robot_vacuum')),
  color       text          not null default '#F2F2F2' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  created_at  timestamptz   not null default now()
);

-- Indexes for the price slider, category filter and "newest" sort.
create index if not exists products_price_idx      on public.products (price);
create index if not exists products_category_idx   on public.products (category);
create index if not exists products_created_at_idx on public.products (created_at desc, id desc);

-- Admins: the only accounts allowed to add, edit or delete products.
-- Create the account in Dashboard -> Authentication -> Users -> Add user,
-- then list it here (see "Make an account an admin" at the end of this file).
create table if not exists public.admins (
  user_id    uuid        primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.admins enable row level security;

-- Signed-in accounts may only check whether they themselves are an admin.
-- Nobody can add admins through the API; that happens in the SQL editor.
revoke all on public.admins from anon, authenticated;
grant select on public.admins to authenticated;

drop policy if exists "Accounts can see their own admin row" on public.admins;
create policy "Accounts can see their own admin row" on public.admins
  for select to authenticated using (user_id = (select auth.uid()));

-- Row Level Security for products: everyone, signed in or not, can browse
-- the catalogue, but only admins can change it.
alter table public.products enable row level security;

revoke all on public.products from anon, authenticated;
grant select on public.products to anon;
grant select, insert, update, delete on public.products to authenticated;

-- Remove the open write policies from the first version of this file.
drop policy if exists "Anyone can add products"    on public.products;
drop policy if exists "Anyone can update products" on public.products;
drop policy if exists "Anyone can delete products" on public.products;

drop policy if exists "Anyone can view products"   on public.products;
drop policy if exists "Admins can add products"    on public.products;
drop policy if exists "Admins can update products" on public.products;
drop policy if exists "Admins can delete products" on public.products;

create policy "Anyone can view products" on public.products
  for select to anon, authenticated using (true);

create policy "Admins can add products" on public.products
  for insert to authenticated
  with check (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

create policy "Admins can update products" on public.products
  for update to authenticated
  using      (exists (select 1 from public.admins a where a.user_id = (select auth.uid())))
  with check (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

create policy "Admins can delete products" on public.products
  for delete to authenticated
  using (exists (select 1 from public.admins a where a.user_id = (select auth.uid())));

-- Make an account an admin. Run this on its own, with the email of the
-- account you created under Authentication -> Users:
--
--   insert into public.admins (user_id)
--   select id from auth.users where email = 'you@example.com'
--   on conflict do nothing;
