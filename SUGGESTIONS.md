# Design suggestions for FACET

These come from 3D e-commerce sites on Awwwards: the E-commerce winners list
(`/websites/winner_category_ecommerce/`) and the E-commerce category. For each
site there's a note on what FACET already borrows and what to try next.

## Reference sites

| Site (studio) | What stands out | In FACET now | Try next |
| --- | --- | --- | --- |
| **Solara Halo S1** (OXVO): "one live Three.js product stays on stage from the first scroll through finishes, specs, cart and preorder" | One object is the whole experience | Hero torus you can grab; the card object flies into the product page | Keep the object on stage while the specs scroll past. Add **finish swatches that recolor the 3D object live** before you add it to the bag |
| **Aether 1** (OFF+BRAND., Site of the Day): earbud launch mixing 3D WebGL and an AI chat | Product, story and Q&A on one page | Spec rows on the product page | **Hotspots on the 3D object** (tap a point to see that spec) and an "Ask about this object" chat |
| **SPYLT Milk** (Tubik, Site of the Day) | Loud color blocking, scroll-driven 3D, playful type | Each product's color tints its own card | **Rotate the hero object as you scroll**, and give each category its own background color when that filter is active |
| **Arc'teryx System_0™** | Story and shopping in one interface | — | **Collection stories**: short editorial pages ("The Desk Edit") with products you can buy inline |
| **Qudrix** (O0, Site of the Day) | Turns a configurable product into a game | The admin form already has a live 3D shape and color preview | Give customers a **configurator**: pick a shape and finish, and the price updates |
| **Monolith** (CUSP, Site of the Day) | Gallery-style minimalism, objects shown like art | Mono uppercase labels, lots of dark space, spec table | Larger product-page typography; a "gallery" toggle with one object per screen |
| **Telepathic Instruments** (Love and Money, Site of the Day) | A hardware product with lots of interaction | Tilt, glare and drag-to-spin | Subtle **sound and haptics** on add-to-bag and page changes, with a mute option |

## Design ideas, in priority order

1. **Scroll-linked hero.** Drive the torus's yaw from the scroll offset (`ScrollController.offset * k`) so it turns as you scroll down the catalogue (SPYLT).
2. **Live finish swatches on the product page.** Add a `product_variants` table (color, price delta, stock). Tapping a swatch tweens the mesh color (Solara).
3. **Price histogram above the slider.** Show a small bar chart of how many products fall in each price band so the slider is easier to use. Compute it with a Postgres RPC (`width_bucket`) so it stays a backend query.
4. **Real product models.** When you have GLB files, store them in Supabase Storage and render them with `model_viewer_plus`. Keep the current Dart renderer as the fast placeholder in grid cards.
5. **3D hotspots.** Project chosen mesh vertices to the screen (the painter already projects every vertex) and pin small labels to them (Aether 1).
6. **Category worlds.** Each category gets an accent and a background gradient that cross-fade when you switch filters.
7. **Page-change motion.** Stagger the new page's cards in (fade up, 40 ms apart) instead of fading the whole grid.
8. **Collection stories.** Add an editorial page type that mixes text and product cards (Arc'teryx).

## Engineering suggestions

1. **Lock down write access (most important).** `schema.sql` lets the public
   `anon` role insert, update and delete, because the activity has no login.
   Before using real data, add Supabase Auth and an `admins` table (or a
   custom claim). Then limit insert, update and delete to admins, and keep
   `select` public.
   ```sql
   create policy "Admins manage products" on public.products
     for all to authenticated
     using (exists (select 1 from admins a where a.user_id = auth.uid()))
     with check (exists (select 1 from admins a where a.user_id = auth.uid()));
   ```
2. **Shareable URLs.** Your repo already has a `go_route` branch. Put the page
   and filters in the query string (`/shop?page=2&min=500&max=5000`) so links
   and the browser back button work on Flutter web.
3. **Realtime refresh.** Subscribe to `products` changes with
   `supabase.channel(...).onPostgresChanges(...)` so other open sessions see
   edits immediately.
4. **Save the bag.** Store bag lines in a `bag_items` table per user (or in
   `shared_preferences` for guests) so the bag survives a restart.
5. **Search descriptions too.** Use a Postgres full-text index (`tsvector`)
   and `.textSearch()` instead of `ilike` on the name only.
6. **Keyset pagination.** If the catalogue grows to thousands of rows, page
   with `.lt('id', lastId)` instead of large offsets. Offsets get slower as
   the page number grows.
