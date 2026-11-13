# FACET — 3D Object Store

**CS Elective 2 · Supabase-Flutter Activity: Price Filter + Pagination**
Branch: `backend-filter-pagination`

FACET is a Flutter storefront backed by Supabase. Every product is drawn as a
live, shaded 3D object by a small renderer written in pure Dart, so you don't
need any 3D model files.

## Activity checklist

| Requirement | Where it lives |
| --- | --- |
| **Price filter**: customers pick a price range with a slider and the list updates | `RangeSlider` in [`lib/widgets/filter_panel.dart`](lib/widgets/filter_panel.dart) → `ShopController.setPriceRange` → `.gte('price')` / `.lte('price')` in [`lib/data/product_repository.dart`](lib/data/product_repository.dart) |
| **Pagination**: 6–8 products per page | `kPageSize = 8` in [`lib/state/shop_controller.dart`](lib/state/shop_controller.dart) |
| Pagination done with a **Supabase query** | `.range(from, to).count(CountOption.exact)`: Postgres returns only the 8 rows for the page plus the total count |
| Handled on the frontend with **state management** | Riverpod `NotifierProvider` (`ShopController` / `ShopState`) holds the page, total, filters and loading/error state; the UI only renders that state |
| Update / delete / filter from the class session | Edit and Delete on the product page, “New object” in the top bar, plus category, search and sort filters |

All filters run on the server and are combined in one query: search (`ilike`),
category (`eq`), price range (`gte`/`lte`), sort (`order`) and page (`range`).
Changing any filter sends you back to page 1. If you delete the last item on
the last page, the app moves you to the new last page.

## Design

A dark "studio" look: products are the only bright colors on screen, lit like
objects on a photo set, with a single acid-lime accent for actions. It's based
on 3D commerce sites from Awwwards' e-commerce category (Solara Halo S1,
Aether 1, SPYLT, Arc'teryx System_0, Qudrix). See
[`SUGGESTIONS.md`](SUGGESTIONS.md) for what was borrowed from each site and
ideas for what to build next.

- **Live 3D products** ([`lib/three_d/`](lib/three_d)): the renderer handles rotation, perspective, back-face culling, depth sorting, and key, fill, specular and rim lighting. There are six forms (cube, sphere, torus, cylinder, cone, gem).
- **Tilt cards**: each card leans toward the cursor in 3D perspective, with a moving glare and parallax on the object.
- **Grab-to-spin**: drag the hero torus, a product page object or the form preview to rotate it. It keeps spinning with momentum.
- The product object flies from the card into the product page (Hero animation).
- The idle spin stops when the device asks for reduced motion.

## Setup

1. **Create the database.** In your Supabase project, open **SQL Editor** and
   run [`supabase/schema.sql`](supabase/schema.sql), then
   [`supabase/seed.sql`](supabase/seed.sql). This creates 24 products, or 3 pages.
2. **Add your keys.** Copy `env.example.json` to `env.json`, then fill in the
   Project URL and publishable key from **Project Settings → API Keys**.
   `env.json` is git-ignored.
3. **Run it.**
   ```bash
   flutter pub get
   flutter run --dart-define-from-file=env.json
   ```
   In VS Code, press **F5**. The launch configs in `.vscode/launch.json`
   already pass `env.json`.

If the keys are missing, the app opens a setup screen instead of crashing.

## Project structure

```
lib/
  main.dart                    Supabase.initialize + ProviderScope
  config/env.dart              keys from --dart-define-from-file
  data/product_repository.dart all Supabase queries (filter, range, count, CRUD)
  models/product.dart          Product model, ₱ formatting
  state/shop_controller.dart   Riverpod: pagination + filter state
  state/shop_filter.dart       search / category / price / sort
  state/bag_controller.dart    in-memory shopping bag
  three_d/                     mesh, shapes, painter, SpinningMesh widget
  widgets/                     filter panel, pagination bar, cards, form, bag
  screens/                     shop, product detail, setup
supabase/
  schema.sql                   table, indexes, RLS policies
  seed.sql                     24 sample products
```

## Tests

```bash
flutter test
```

The tests drive `ShopController` with an in-memory repository. They cover
page size, next and last page, the price range, category plus search, and
deleting the last item on a page. A second set checks that every face of the
3D shapes points outward.
