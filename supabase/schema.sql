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

-- Row Level Security.
-- This class project has no login screen, so the public (anon) role may
-- read AND add/edit/delete products. Fine for a demo; see SUGGESTIONS.md
-- before putting real data behind these keys.
alter table public.products enable row level security;

grant select, insert, update, delete on public.products to anon, authenticated;

drop policy if exists "Anyone can view products"   on public.products;
drop policy if exists "Anyone can add products"    on public.products;
drop policy if exists "Anyone can update products" on public.products;
drop policy if exists "Anyone can delete products" on public.products;

create policy "Anyone can view products"   on public.products for select to anon, authenticated using (true);
create policy "Anyone can add products"    on public.products for insert to anon, authenticated with check (true);
create policy "Anyone can update products" on public.products for update to anon, authenticated using (true) with check (true);
create policy "Anyone can delete products" on public.products for delete to anon, authenticated using (true);
