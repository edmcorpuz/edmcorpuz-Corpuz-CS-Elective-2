# FACET — 3D Appliance Store

**CS Elective 2 · Final Exam: E-Commerce App**
Branch: `final-exam` (builds on `backend-filter-pagination` and `backend-auth`)

### ▶ [Open the live website](https://edmcorpuz.github.io/edmcorpuz-Corpuz-CS-Elective-2/)

FACET is a Flutter home-appliance store backed by Supabase, with two roles:
**admins** manage the catalogue and orders, and **customers** shop and keep
their order history. Every product is a live 3D appliance drawn by a small
renderer written in pure Dart, plus an optional photo in Supabase Storage.

| Area | What FACET uses |
| --- | --- |
| State management | Riverpod (`Notifier`, `AsyncNotifier`, `Provider`) |
| Backend | Supabase Auth, Postgres, Row Level Security |
| Sign-in | Email and password, plus Google |
| Image storage | Supabase Storage bucket `product-images` |

## Final Exam checklist

### Roles and permissions

| Capability | Signed out | Customer | Admin | How it's enforced |
| --- | --- | --- | --- | --- |
| Sign up, log in (email or Google) | Yes | — | — | [`AuthScreen`](lib/screens/auth_screen.dart); `AuthGate` in [`main.dart`](lib/main.dart) shows only this screen when signed out |
| View products and categories | No | Yes | Yes | `select` policies are `to authenticated`; `anon` has no grants at all |
| Add / edit / delete a product | No | No | Yes | `public.is_admin()` in the insert/update/delete policies; buttons only in the admin UI |
| Add to cart, place an order, view own orders | No | Yes | No | `place_order()` refuses admins; orders policy returns only `user_id = auth.uid()` for customers |

Every new account starts as a customer: the `on_auth_user_created` trigger
creates its `profiles` row with role `customer`. A profile's role can't be
changed from the app (only `firstname` and `lastname` are granted for
update), so making someone an admin happens in the SQL Editor.

### Admin

| Requirement | Where it lives |
| --- | --- |
| Product list with a floating “Add product” button | [`ShopScreen`](lib/screens/shop_screen.dart) (FAB shown only to admins) |
| Edit & Delete buttons on each product card | [`ProductCard`](lib/widgets/product_card.dart) `onEdit` / `onDelete` |
| Product form: name, description, price, stock, category, image | [`ProductForm`](lib/widgets/product_form.dart); photo uploaded with `image_picker` → Supabase Storage |
| Edit pre-fills every field | `ProductForm(initial: product)` |
| Delete asks first, naming the product | [`confirmDelete`](lib/widgets/confirm_delete.dart) |
| Validation: name required, price ≥ 0, stock a whole number ≥ 0 | Form validators, backed by `check` constraints in [`schema.sql`](supabase/schema.sql) |
| Category management | [`CategoriesScreen`](lib/screens/categories_screen.dart): add, rename (products keep pointing at the same `category_id`), delete (blocked while products use it) |
| Admin order list, update status | [`OrdersScreen`](lib/screens/orders_screen.dart) with a status dropdown → `orders.status` (the only column admins may update) |

### Customer

| Requirement | Where it lives |
| --- | --- |
| Filters from the last activity | Search, category, price slider, sort and 8-per-page pagination, all in one Supabase query ([`product_repository.dart`](lib/data/product_repository.dart)) |
| Product list without admin buttons, with Add to cart | `ProductCard` shows `onAddToBag` for customers |
| Cart: add, change quantity, remove, running total and item count | [`CartScreen`](lib/screens/cart_screen.dart) + [`BagController`](lib/state/bag_controller.dart) |
| No more than the stock; no sold-out products | `BagController.add` stops at `product.stock`; the database checks again at checkout |
| Cart survives screen changes, empties after an order and on logout | Riverpod state; rebuilt whenever the signed-in user changes; `clear()` after checkout |
| Checkout saves the order and its items, or nothing | `public.place_order(items jsonb)`: one transaction, any error rolls everything back |
| Prices, names and stock come from the database | The app sends only product ids and quantities; the function reads (and locks) each product row |
| Stock is reduced in the same operation | `update products set stock = stock - quantity` inside `place_order` |
| Items keep a snapshot of name and price | `order_items.product_name` and `unit_price`; `product_id` is `on delete set null` |
| Confirmation with order number and total | [`OrderConfirmationScreen`](lib/screens/order_confirmation_screen.dart) |
| Order history: own orders, newest first, status, date, total, items | `OrdersScreen` for customers |

### Database schema

The tables follow the required schema diagram: `roles` (`id`, `role`, `created_at`, `encoded_by`), `profiles` (`id`, `created_at`, `email`, `firstname`, `lastname`, `role_id`), `categories`, `products` (`category_id`, `price` float4, `stock` int2, `image_url`), `orders` (`user_id` → `auth.users`) and `order_items`. Two columns are added on purpose: `order_items.product_name`, the name snapshot the manual requires, and `products.model` / `color`, which pick the 3D appliance and its finish. A database made by an earlier version is upgraded with [`supabase/migrate_to_required_schema.sql`](supabase/migrate_to_required_schema.sql).

### Row Level Security

| Table | Signed out | Customer | Admin |
| --- | --- | --- | --- |
| `profiles` | No access | Read and update own row only, never the role | Read all |
| `roles` | No access | Read | Read |
| `categories` | No access | Read | Read, add, edit, delete |
| `products` | No access | Read | Read, add, edit, delete |
| `orders` | No access | Read own only | Read all, update status |
| `order_items` | No access | Read items of own orders only | Read all |

All policies are in [`supabase/schema.sql`](supabase/schema.sql). Why hiding a
button isn't security: the publishable key ships inside the public website, so
anyone can call the API directly. The app hides admin buttons to keep the
screens clean, but it's these policies, the column grants and the checks in
`place_order()` that actually stop a customer from editing products, reading
other people's orders or paying their own price.

### Architecture

```
screens/   → watch and call providers only (no Supabase code)
state/     → Riverpod providers and controllers (shop, cart, account, orders)
data/      → services: the only code that talks to Supabase
models/    → Product, Order, OrderItem
widgets/   → reusable UI (cards, form, filters, dialogs)
three_d/   → the 3D renderer and appliance models
```

Every async provider's loading, empty and error states are drawn (catalogue,
orders, categories, checkout). Text controllers, tickers and the auth-state
subscription are disposed.

## Design

A dark "studio" look: the appliances are the only bright colors on screen, lit
like products on a photo set, with a single acid-lime accent for actions. It's
based on 3D commerce sites from Awwwards' e-commerce category (Solara Halo S1,
Aether 1, SPYLT, Arc'teryx System_0, Qudrix). See
[`SUGGESTIONS.md`](SUGGESTIONS.md) for what was borrowed from each site and
ideas for what to build next.

- **Hover animations.** Hover a card and the appliance lifts, turns to face you and works:

  | Appliance | On hover |
  | --- | --- |
  | Fridge | the door swings open onto a lit interior |
  | Washer | shakes while the drum spins behind the glass |
  | Microwave | the window glows |
  | TV | the screen turns on with a moving picture |
  | Fan | the blades go full speed |
  | Aircon | the flap opens and air flows out |
  | Rice cooker | the lid opens and steam rises |
  | Blender | runs |
  | Air fryer | the basket slides out with fries |
  | Toaster | the toast pops up |
  | Kettle | the LED ring glows and steam comes out |
  | Robot vacuum | the side brush spins |

  The card tilts toward the cursor, the spotlight brightens, and an action tag slides in. On the product page, a button plays the same animation for touch screens.
- **Collapsible filter panel.** On desktop, the « button folds the sidebar into a slim rail, and » opens it again. A dot shows when filters are active.
- **Live 3D renderer** ([`lib/three_d/`](lib/three_d)): appliances are built from primitives (boxes, cylinders, ellipsoids, rings). Moving parts use hinges, slides, spins and growth. The renderer handles perspective, back-face culling, depth sorting, see-through glass, glowing lamps and screens, and key, fill, specular and rim lighting.
- Appliances sway gently around a three-quarter front view. You can drag the hero fan, a product page model or the form preview to rotate it.
- The model flies from the card into the product page (Hero animation). Motion stops when the device asks for reduced motion.

## Setup

1. **Create the database.** In your Supabase project, open **SQL Editor** and
   run [`supabase/schema.sql`](supabase/schema.sql), then
   [`supabase/seed.sql`](supabase/seed.sql). This creates the tables, the
   checkout function, the sign-up trigger, the image bucket, every RLS policy,
   6 categories and 24 appliances (₱1,190 to ₱54,990, 3 pages).
2. **Turn on Google sign-in.**
   - In Google Cloud Console, create an **OAuth client ID** of type **Web
     application**. Add `https://<project-ref>.supabase.co/auth/v1/callback`
     as an authorized redirect URI.
   - In Supabase, open **Authentication → Sign In / Providers → Google**, turn
     it on, paste the Client ID and Client Secret, and save.
   - In **Authentication → URL Configuration**, set the Site URL to the
     website and add these Redirect URLs: the website followed by `**`,
     `http://localhost:*/**` (local testing) and
     `io.supabase.facetshop://login-callback/` (the phone app).
3. **Make yourself an admin.** Sign up in the app, then run this in the SQL
   Editor with your email:
   ```sql
   update public.profiles set role_id = 2 where email = 'you@example.com';
   ```
4. **Add your keys.** Copy `env.example.json` to `env.json`, then fill in the
   Project URL and publishable key from **Project Settings → API Keys**.
   `env.json` is git-ignored.
5. **Run it.**
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```
   In VS Code, press **F5**. The launch configs in `.vscode/launch.json`
   already pass `env.json`.

If the keys are missing, the app opens a setup screen instead of crashing.

## Updating the live website

The live site is hosted on GitHub Pages from the `gh-pages` branch, which
holds only the built web files. After changing the code, rebuild and publish
it with one command (PowerShell, from the project folder):

```powershell
./tool/deploy_web.ps1
```

The script builds the app with your `env.json` keys and the right base path
for GitHub Pages, then replaces the `gh-pages` branch with the new build. The
site updates about a minute later.

## Project structure

```
lib/
  main.dart                         Supabase.initialize, ProviderScope, AuthGate
  config/env.dart                   keys from --dart-define-from-file
  data/product_repository.dart      products, categories, photo upload
  data/order_repository.dart        place_order(), order list, status updates
  data/auth_repository.dart         email sign-up/in, Google, role lookup
  models/product.dart, order.dart   rows as Dart objects, ₱ formatting
  state/shop_controller.dart        catalogue: pagination, filters, categories
  state/bag_controller.dart         the cart
  state/orders_controller.dart      order list + checkout
  state/account_controller.dart     who is signed in, admin or customer
  screens/                          auth, shop, product detail, cart,
                                    confirmation, orders, categories, setup
  widgets/                          cards, product form, filters, dialogs
  three_d/                          3D renderer and the 12 appliance models
supabase/
  schema.sql                        tables, functions, trigger, storage, RLS
  seed.sql                          6 categories, 24 appliances
tool/
  deploy_web.ps1                    build + publish the live site to GitHub Pages
```

## Tests

```bash
flutter test
```

- **Catalogue:** page size, next and last page, price range, category plus
  search, deleting the last item on a page, renaming a category (its products
  and the active filter follow) and refusing to delete a category in use.
- **Accounts:** email sign-up and sign-in, Google sign-in, admins vs
  customers, the gate waiting for the role, a cancelled Google sign-in, wrong
  passwords, duplicate sign-ups and signing out.
- **Cart:** running total and count, stock limits, sold-out products,
  quantity changes and removal, emptying on logout.
- **Orders:** reading an order with its snapshot items, and checkout and
  permission errors shown as plain sentences.
- **3D:** every primitive's faces point outward, all 12 models build and fit
  on screen, and the fridge door swings toward the viewer.
