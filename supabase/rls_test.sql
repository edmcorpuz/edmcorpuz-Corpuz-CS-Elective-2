-- Proves the RLS rules and checkout integrity against the real database.
-- Run in the SQL Editor after schema.sql and seed.sql. It acts as a signed-out
-- visitor, a throwaway customer and the first admin, then ends by raising an
-- error that carries the results, which rolls back everything it did.
-- Expected: every line ends in "ok".
do $$
declare
  admin_id uuid := (select id from public.profiles where role_id = 2 limit 1);
  cust_id  uuid := gen_random_uuid();
  pid      bigint := (select id from public.products where stock >= 2 order by id limit 1);
  price    numeric := (select p.price from public.products p where p.id = pid);
  stock0   int := (select stock from public.products where id = pid);
  results  text[] := '{}';
  n        int;
  o        public.orders;
begin
  if admin_id is null then raise exception 'Make an admin first (see the end of schema.sql).'; end if;

  -- Throwaway customer; the sign-up trigger gives it a customer profile.
  insert into auth.users (id, instance_id, aud, role, email)
  values (cust_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated', 'rls-test@example.invalid');
  results := results || format('trigger made a customer profile: %s',
    case when (select role_id from public.profiles where id = cust_id) = 1 then 'ok' else 'FAIL' end);

  -- Signed out ---------------------------------------------------------------
  perform set_config('role', 'anon', true);
  begin
    perform count(*) from public.products;
    results := results || text 'signed out reads products: FAIL';
  exception when insufficient_privilege then
    results := results || text 'signed out reads products: denied ok';
  end;
  begin
    perform public.place_order('[{"product_id": 1, "quantity": 1}]');
    results := results || text 'signed out places order: FAIL';
  exception when insufficient_privilege then
    results := results || text 'signed out places order: denied ok';
  end;

  -- Customer -------------------------------------------------------------------
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('sub', cust_id, 'role', 'authenticated')::text, true);

  select count(*) into n from public.products;
  results := results || format('customer reads products (%s): %s', n, case when n > 0 then 'ok' else 'FAIL' end);
  begin
    insert into public.products (name, price, category_id) values ('Hack', 1, (select id from public.categories limit 1));
    results := results || text 'customer adds product: FAIL';
  exception when insufficient_privilege then
    results := results || text 'customer adds product: denied ok';
  end;
  update public.products set price = 1 where id = pid;
  get diagnostics n = row_count;
  results := results || format('customer edits product: %s', case when n = 0 then 'blocked ok' else 'FAIL' end);
  delete from public.products where id = pid;
  get diagnostics n = row_count;
  results := results || format('customer deletes product: %s', case when n = 0 then 'blocked ok' else 'FAIL' end);
  begin
    update public.profiles set role_id = 2 where id = cust_id;
    results := results || text 'customer makes self admin: FAIL';
  exception when insufficient_privilege then
    results := results || text 'customer makes self admin: denied ok';
  end;
  update public.profiles set firstname = 'RLS', lastname = 'Test' where id = cust_id;
  get diagnostics n = row_count;
  results := results || format('customer renames own profile: %s', case when n = 1 then 'ok' else 'FAIL' end);
  select count(*) into n from public.profiles;
  results := results || format('customer sees only own profile: %s', case when n = 1 then 'ok' else 'FAIL' end);
  begin
    insert into public.orders (user_id, total) values (cust_id, 0);
    results := results || text 'customer inserts order directly: FAIL';
  exception when insufficient_privilege then
    results := results || text 'customer inserts order directly: denied ok';
  end;

  -- Checkout: a made-up price in the request must be ignored.
  o := public.place_order(format('[{"product_id": %s, "quantity": 2, "price": 1}]', pid)::jsonb);
  results := results || format('checkout uses database price (%s = 2 x %s): %s', o.total, price,
    case when o.total = price * 2 and o.status = 'done' then 'ok' else 'FAIL' end);
  results := results || format('checkout reduced stock: %s',
    case when (select stock from public.products where id = pid) = stock0 - 2 then 'ok' else 'FAIL' end);
  results := results || format('checkout saved name/price snapshot: %s',
    case when exists (select 1 from public.order_items where order_id = o.id and unit_price = price and quantity = 2)
         then 'ok' else 'FAIL' end);
  begin
    perform public.place_order(format('[{"product_id": %s, "quantity": 100000}]', pid)::jsonb);
    results := results || text 'checkout beyond stock: FAIL';
  exception when sqlstate 'P0001' then
    results := results || text 'checkout beyond stock: refused ok';
  end;
  results := results || format('failed checkout saved nothing: %s',
    case when (select count(*) from public.orders where user_id = cust_id) = 1 then 'ok' else 'FAIL' end);
  update public.orders set status = 'cancelled' where id = o.id;
  get diagnostics n = row_count;
  results := results || format('customer changes order status: %s', case when n = 0 then 'blocked ok' else 'FAIL' end);

  -- Admin ----------------------------------------------------------------------
  perform set_config('request.jwt.claims', json_build_object('sub', admin_id, 'role', 'authenticated')::text, true);
  select count(*) into n from public.orders where id = o.id;
  results := results || format('admin reads all orders: %s', case when n = 1 then 'ok' else 'FAIL' end);
  select count(*) into n from public.order_items where order_id = o.id;
  results := results || format('admin reads all order items: %s', case when n = 1 then 'ok' else 'FAIL' end);
  select count(*) into n from public.profiles where id = cust_id;
  results := results || format('admin reads all profiles: %s', case when n = 1 then 'ok' else 'FAIL' end);
  update public.orders set status = 'shipped' where id = o.id;
  get diagnostics n = row_count;
  results := results || format('admin updates order status: %s', case when n = 1 then 'ok' else 'FAIL' end);
  begin
    update public.orders set total = 0 where id = o.id;
    results := results || text 'admin edits order total: FAIL';
  exception when insufficient_privilege then
    results := results || text 'admin edits order total: denied ok';
  end;
  insert into public.categories (name) values ('RLS Test Category');
  results := results || text 'admin adds category: ok';
  update public.products set stock = stock where id = pid;
  get diagnostics n = row_count;
  results := results || format('admin edits product: %s', case when n = 1 then 'ok' else 'FAIL' end);
  begin
    perform public.place_order(format('[{"product_id": %s, "quantity": 1}]', pid)::jsonb);
    results := results || text 'admin places order: FAIL';
  exception when insufficient_privilege then
    results := results || text 'admin places order: refused ok';
  end;

  perform set_config('role', 'postgres', true);
  raise exception E'RLS TEST RESULTS (all rolled back):\n%', array_to_string(results, E'\n');
end $$;
