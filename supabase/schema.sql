-- FACET appliance store: the whole database for the Final Exam e-commerce app.
-- Run this in Supabase Dashboard -> SQL Editor, then run seed.sql.
-- Safe to re-run. It also upgrades a database made by the earlier activity
-- versions of this file (it moves the old `admins` table into profiles).

-- 1. Roles and profiles -------------------------------------------------------

create table if not exists public.roles (
  id   smallint primary key,
  name text     not null unique
);

insert into public.roles (id, name) values (1, 'customer'), (2, 'admin')
on conflict (id) do nothing;

create table if not exists public.profiles (
  id         uuid        primary key references auth.users (id) on delete cascade,
  email      text,
  full_name  text,
  avatar_url text,
  role_id    smallint    not null default 1 references public.roles (id),
  created_at timestamptz not null default now()
);

-- Every new account (email or Google) gets a profile and starts as a customer.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, email, full_name, avatar_url)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Accounts created before the trigger existed.
insert into public.profiles (id, email, full_name, avatar_url)
select id,
       email,
       coalesce(raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'name'),
       raw_user_meta_data ->> 'avatar_url'
from auth.users
on conflict (id) do nothing;

-- Used by every admin policy. security definer so the profiles policy can
-- call it without checking itself again.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles where id = (select auth.uid()) and role_id = 2
  );
$$;

-- 2. Categories and products --------------------------------------------------

create table if not exists public.categories (
  id         bigint      generated always as identity primary key,
  name       text        not null unique check (char_length(name) between 1 and 40),
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id          bigint        generated always as identity primary key,
  name        text          not null check (char_length(name) between 1 and 80),
  description text          not null default '',
  price       numeric(10,2) not null check (price >= 0),
  -- Points at categories.name, so renaming a category renames it here too.
  category    text          not null,
  stock       integer       not null default 0 check (stock >= 0),
  -- Which 3D appliance model the app draws for this product.
  model       text          not null default 'fridge'
              check (model in ('fridge', 'washer', 'microwave', 'tv', 'fan', 'aircon',
                               'rice_cooker', 'blender', 'air_fryer', 'toaster', 'kettle',
                               'robot_vacuum')),
  color       text          not null default '#F2F2F2' check (color ~ '^#[0-9A-Fa-f]{6}$'),
  image_url   text,
  created_at  timestamptz   not null default now()
);

-- Upgrades for databases made by the earlier versions of this file.
alter table public.products add column if not exists image_url text;

insert into public.categories (name)
select distinct category from public.products
on conflict (name) do nothing;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'products_category_fkey') then
    alter table public.products
      add constraint products_category_fkey
      foreign key (category) references public.categories (name) on update cascade;
  end if;
end $$;

create index if not exists products_price_idx      on public.products (price);
create index if not exists products_category_idx   on public.products (category);
create index if not exists products_created_at_idx on public.products (created_at desc, id desc);

-- 3. Orders -------------------------------------------------------------------

create table if not exists public.orders (
  id         bigint        generated always as identity primary key,
  user_id    uuid          not null references public.profiles (id) on delete cascade,
  status     text          not null default 'pending'
             check (status in ('pending', 'done', 'shipped', 'cancelled')),
  total      numeric(12,2) not null default 0 check (total >= 0),
  created_at timestamptz   not null default now()
);

create index if not exists orders_user_created_idx on public.orders (user_id, created_at desc);

create table if not exists public.order_items (
  id           bigint        generated always as identity primary key,
  order_id     bigint        not null references public.orders (id) on delete cascade,
  -- Kept as a snapshot: deleting the product later leaves the history intact.
  product_id   bigint        references public.products (id) on delete set null,
  product_name text          not null,
  unit_price   numeric(10,2) not null check (unit_price >= 0),
  quantity     integer       not null check (quantity > 0)
);

create index if not exists order_items_order_idx on public.order_items (order_id);

-- Checkout. Runs as one transaction: the order, its items and the stock
-- changes are all saved, or (on any error) none of them are.
create or replace function public.place_order(items jsonb)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order   public.orders;
  v_line    record;
  v_product public.products;
  v_total   numeric(12,2) := 0;
begin
  if (select auth.uid()) is null then
    raise exception 'Sign in to place an order.' using errcode = '42501';
  end if;
  if public.is_admin() then
    raise exception 'Admin accounts can''t place orders.' using errcode = '42501';
  end if;
  if items is null or jsonb_typeof(items) <> 'array' or jsonb_array_length(items) = 0 then
    raise exception 'Your cart is empty.' using errcode = '22023';
  end if;

  insert into public.orders (user_id) values ((select auth.uid())) returning * into v_order;

  -- The same product twice counts once; sorted ids lock rows in a fixed order.
  for v_line in
    select (e ->> 'product_id')::bigint     as product_id,
           sum((e ->> 'quantity')::integer) as quantity
    from jsonb_array_elements(items) as e
    group by 1
    order by 1
  loop
    if v_line.product_id is null or v_line.quantity is null or v_line.quantity < 1 then
      raise exception 'Every cart line needs a product and a quantity of at least 1.'
        using errcode = '22023';
    end if;

    -- Name, price and stock come from the database, never from the app.
    select * into v_product from public.products where id = v_line.product_id for update;
    if not found then
      raise exception 'A product in your cart is no longer sold.' using errcode = 'P0002';
    end if;
    if v_product.stock < v_line.quantity then
      raise exception 'Only % left of %.', v_product.stock, v_product.name using errcode = 'P0001';
    end if;

    update public.products set stock = stock - v_line.quantity where id = v_product.id;

    insert into public.order_items (order_id, product_id, product_name, unit_price, quantity)
    values (v_order.id, v_product.id, v_product.name, v_product.price, v_line.quantity);

    v_total := v_total + v_product.price * v_line.quantity;
  end loop;

  update public.orders set total = v_total, status = 'done'
  where id = v_order.id
  returning * into v_order;

  return v_order;
end;
$$;

revoke all on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

-- Earlier versions kept admins in their own table. Move them to profiles.
do $$
begin
  if to_regclass('public.admins') is not null then
    update public.profiles set role_id = 2
    where id in (select user_id from public.admins);
    drop policy if exists "Admins can add products"    on public.products;
    drop policy if exists "Admins can update products" on public.products;
    drop policy if exists "Admins can delete products" on public.products;
    drop table public.admins;
  end if;
end $$;

-- 4. Product images (Supabase Storage) ----------------------------------------

-- Public bucket: anyone with the link can view a photo; only admins can
-- upload, replace or delete one.
insert into storage.buckets (id, name, public)
values ('product-images', 'product-images', true)
on conflict (id) do nothing;

drop policy if exists "Admins upload product images"  on storage.objects;
drop policy if exists "Admins replace product images" on storage.objects;
drop policy if exists "Admins delete product images"  on storage.objects;

create policy "Admins upload product images" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'product-images' and public.is_admin());

create policy "Admins replace product images" on storage.objects
  for update to authenticated
  using      (bucket_id = 'product-images' and public.is_admin())
  with check (bucket_id = 'product-images' and public.is_admin());

create policy "Admins delete product images" on storage.objects
  for delete to authenticated
  using (bucket_id = 'product-images' and public.is_admin());

-- 5. Row Level Security -------------------------------------------------------
-- Signed-out visitors (anon) get nothing. Customers read the catalogue and
-- their own orders. Admins manage the catalogue and read all orders.

alter table public.roles       enable row level security;
alter table public.profiles    enable row level security;
alter table public.categories  enable row level security;
alter table public.products    enable row level security;
alter table public.orders      enable row level security;
alter table public.order_items enable row level security;

revoke all on public.roles, public.profiles, public.categories, public.products,
              public.orders, public.order_items
  from anon, authenticated;

grant select on public.roles, public.profiles, public.categories, public.products,
                public.orders, public.order_items
  to authenticated;
grant insert, update, delete on public.categories, public.products to authenticated;
-- Column grants: a profile's role and an order's contents can never be
-- changed from the app, whatever the policies say.
grant update (full_name, avatar_url) on public.profiles to authenticated;
grant update (status) on public.orders to authenticated;

-- Start from a clean slate of policies on these tables.
do $$
declare
  p record;
begin
  for p in
    select policyname, tablename from pg_policies
    where schemaname = 'public'
      and tablename in ('roles', 'profiles', 'categories', 'products', 'orders', 'order_items')
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- profiles: customers read and update their own row (never the role);
-- admins read every profile.
create policy "Read own profile, admins read all" on public.profiles
  for select to authenticated
  using (id = (select auth.uid()) or public.is_admin());

create policy "Update own profile" on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

-- roles: readable by everyone signed in.
create policy "Signed-in users read roles" on public.roles
  for select to authenticated using (true);

-- categories and products: everyone signed in reads; admins change.
create policy "Signed-in users read categories" on public.categories
  for select to authenticated using (true);
create policy "Admins add categories" on public.categories
  for insert to authenticated with check (public.is_admin());
create policy "Admins edit categories" on public.categories
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins delete categories" on public.categories
  for delete to authenticated using (public.is_admin());

create policy "Signed-in users read products" on public.products
  for select to authenticated using (true);
create policy "Admins add products" on public.products
  for insert to authenticated with check (public.is_admin());
create policy "Admins edit products" on public.products
  for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "Admins delete products" on public.products
  for delete to authenticated using (public.is_admin());

-- orders: customers read their own; admins read all and update the status.
-- Nobody inserts directly: orders are only created by place_order().
create policy "Read own orders, admins read all" on public.orders
  for select to authenticated
  using (user_id = (select auth.uid()) or public.is_admin());
create policy "Admins update order status" on public.orders
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- order_items: customers read the items of their own orders; admins read all.
create policy "Read items of own orders, admins read all" on public.order_items
  for select to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.user_id = (select auth.uid())
    )
  );

-- Make an account an admin. Run this on its own, with the account's email:
--
--   update public.profiles set role_id = 2 where email = 'you@example.com';
