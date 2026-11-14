# FACET — 3D Appliance Store

**CS Elective 2 · Supabase-Flutter Activity: Price Filter + Pagination**
Branch: `backend-filter-pagination`

### ▶ [Open the live website](https://edmcorpuz.github.io/edmcorpuz-Corpuz-CS-Elective-2/)

`https://edmcorpuz.github.io/edmcorpuz-Corpuz-CS-Elective-2/`: the app
running in your browser against the real Supabase database. Nothing to install.

FACET is a Flutter home-appliance store backed by Supabase. Every product is
a live 3D appliance (fridge, washer, microwave, TV, fan, aircon, rice cooker,
blender, air fryer, toaster, kettle or robot vacuum). Each one is drawn by a
small renderer written in pure Dart, so you don't need any 3D model files.

## Activity checklist

| Requirement | Where it lives |
| --- | --- |
| **Price filter**: customers pick a price range with a slider and the list updates | `RangeSlider` in [`lib/widgets/filter_panel.dart`](lib/widgets/filter_panel.dart) → `ShopController.setPriceRange` → `.gte('price')` / `.lte('price')` in [`lib/data/product_repository.dart`](lib/data/product_repository.dart) |
| **Pagination**: 6–8 products per page | `kPageSize = 8` in [`lib/state/shop_controller.dart`](lib/state/shop_controller.dart) |
| Pagination done with a **Supabase query** | `.range(from, to).count(CountOption.exact)`: Postgres returns only the 8 rows for the page plus the total count |
| Handled on the frontend with **state management** | Riverpod `NotifierProvider` (`ShopController` / `ShopState`) holds the page, total, filters and loading/error state; the UI only renders that state |
| Update / delete / filter from the class session | Edit and Delete on the product page, “New appliance” in the top bar, plus category, search and sort filters |

All filters run on the server and are combined in one query: search (`ilike`),
category (`eq`), price range (`gte`/`lte`), sort (`order`) and page (`range`).
Changing any filter sends you back to page 1. If you delete the last item on
the last page, the app moves you to the new last page.

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
   [`supabase/seed.sql`](supabase/seed.sql). This creates 24 appliances from
   ₱1,190 to ₱54,990, which is 3 pages.
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
  main.dart                       Supabase.initialize + ProviderScope
  config/env.dart                 keys from --dart-define-from-file
  data/product_repository.dart    all Supabase queries (filter, range, count, CRUD)
  models/product.dart             Product model, ₱ formatting
  state/shop_controller.dart      Riverpod: pagination + filter state
  state/shop_filter.dart          search / category / price / sort
  state/bag_controller.dart       in-memory shopping bag
  three_d/mesh.dart               vectors, mesh, MeshBuilder primitives
  three_d/appliances.dart         the 12 appliance models and their motions
  three_d/appliance_painter.dart  the renderer
  three_d/appliance_view.dart     animated widget (sway, hover, drag)
  widgets/                        filter panel + collapsible sidebar, cards,
                                  pagination bar, form, bag
  screens/                        shop, product detail, setup
supabase/
  schema.sql                      table (with `model` column), indexes, RLS
  seed.sql                        24 sample appliances
tool/
  deploy_web.ps1                  build + publish the live site to GitHub Pages
```

## Tests

```bash
flutter test
```

The tests drive `ShopController` with an in-memory repository. They cover
page size, next and last page, the price range, category plus search, and
deleting the last item on a page. A second set checks that every 3D
primitive's faces point outward, that all 12 appliance models build and fit
on screen, and that the fridge door swings toward the viewer.
