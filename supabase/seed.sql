-- 24 sample products (3 pages of 8) spread from ₱249 to ₱18,990 so the
-- price slider and pagination have something to work with.
-- Safe to re-run: it only inserts when the table is empty.

insert into public.products (name, description, price, category, stock, shape, color, created_at)
select v.name, v.description, v.price, v.category, v.stock, v.shape, v.color, now() - (v.age || ' hours')::interval
from (values
  ('Halo Ring Lamp',       'A floating ring of warm light. Dimmable, USB-C powered, made for bedside shelves.', 4890.00, 'Lighting',  12, 'torus',    '#FFB23F',  1),
  ('Orb Desk Light',       'Hand-blown opal glass sphere that glows like a small moon on your desk.',            2350.00, 'Lighting',   8, 'sphere',   '#F2EDE4',  2),
  ('Beacon Floor Cone',    'A tall cone uplighter that throws a soft wash of light up the wall.',                8990.00, 'Lighting',   3, 'cone',     '#FF6A3D',  3),
  ('Pillar Glow',          'Frosted acrylic column with a slow colour-fade mode.',                               3150.00, 'Lighting',  15, 'cylinder', '#9AD1FF',  4),
  ('Monolith Speaker',     'A solid cube of sound: 60 W, Bluetooth 5.3, felt-wrapped sides.',                   12490.00, 'Audio',      5, 'cube',     '#6E7BFF',  5),
  ('Pebble Earbuds',       'Smooth, pebble-shaped earbuds with 30 hours of battery in the case.',               3990.00, 'Audio',     20, 'sphere',   '#E9E4FF',  6),
  ('Loop Headphone Stand', 'A weighted ring that holds your headphones and keeps cables tidy.',                 1290.00, 'Audio',     25, 'torus',    '#C8FF2E',  7),
  ('Column Soundbar',      'Cylindrical soundbar with room-filling 360° audio.',                                18990.00, 'Audio',      2, 'cylinder', '#FF4F81',  8),
  ('Prism Paperweight',    'Faceted crystal paperweight that throws rainbows across the room.',                  890.00, 'Decor',     30, 'gem',      '#7CF5D4',  9),
  ('Cubo Planter',         'Matte ceramic cube planter with a hidden drainage tray.',                            1450.00, 'Decor',     18, 'cube',     '#E7C9A9', 10),
  ('Donut Vase',           'Glazed ring vase for a single dramatic stem.',                                       1690.00, 'Decor',     10, 'torus',    '#FF8FB1', 11),
  ('Spire Candle',         'Sculpted cone candle, 20-hour burn, unscented soy wax.',                              349.00, 'Decor',     40, 'cone',     '#FFE066', 12),
  ('Block Charging Dock',  'One cube, three devices: phone, watch and earbuds.',                                 2790.00, 'Desk',      14, 'cube',     '#B8F2FF', 13),
  ('Roll Pen Cup',         'Powder-coated steel tube for pens, brushes and rulers.',                              590.00, 'Desk',      35, 'cylinder', '#FF9F45', 14),
  ('Facet Bookend',        'A heavy cut-glass bookend, sold as one.',                                            1190.00, 'Desk',      16, 'gem',      '#A78BFA', 15),
  ('Dot Fidget Sphere',    'Satisfyingly heavy steel sphere to roll while you think.',                            249.00, 'Desk',      50, 'sphere',   '#5CE1E6', 16),
  ('Zen Diffuser',         'Ultrasonic cone diffuser with a warm night-light ring.',                             2190.00, 'Wellness',  11, 'cone',     '#B5E48C', 17),
  ('Orbit Massage Ball',   'Firm textured ball for back and foot release.',                                       690.00, 'Wellness',  28, 'sphere',   '#FF7A59', 18),
  ('Calm Ring Timer',      'Twist the ring to start a silent focus or breathing timer.',                         1590.00, 'Wellness',   9, 'torus',    '#9BF6FF', 19),
  ('Crystal Lamp',         'Salt-crystal gem lamp with a dimmable warm bulb.',                                   2990.00, 'Wellness',   0, 'gem',      '#FFC6FF', 20),
  ('Drum Coffee Grinder',  'Burr grinder in a brushed drum body, 40 grind settings.',                            6450.00, 'Kitchen',    6, 'cylinder', '#D4A373', 21),
  ('Cube Ice Mold',        'Makes four crystal-clear 5 cm ice cubes.',                                            299.00, 'Kitchen',   45, 'cube',     '#A0C4FF', 22),
  ('Funnel Pour-Over',     'Ceramic cone dripper for a clean, bright cup.',                                      1350.00, 'Kitchen',   22, 'cone',     '#FDFFB6', 23),
  ('Kettle Sphere',        'Gooseneck electric kettle with a round 1 L body.',                                   4250.00, 'Kitchen',    7, 'sphere',   '#FFADAD', 24)
) as v(name, description, price, category, stock, shape, color, age)
where not exists (select 1 from public.products);
