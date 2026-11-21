-- 24 sample appliances (3 pages of 8) from ₱1,190 to ₱54,990 so the price
-- slider and pagination have something to work with.
-- Safe to re-run: categories are skipped if present, products only go in
-- when the table is empty.

insert into public.categories (name) values
  ('Refrigeration'), ('Laundry'), ('Kitchen'), ('Cooling'), ('Entertainment'), ('Cleaning')
on conflict (name) do nothing;

insert into public.products (name, description, price, category_id, stock, model, color, created_at)
select v.name, v.description, v.price, c.id, v.stock, v.model, v.color, now() - (v.age || ' hours')::interval
from (values
  ('Frost Two-Door Refrigerator',  '9 cu. ft. inverter fridge with a top freezer, LED interior light and glass shelves.',          28995.00, 'Refrigeration', 6,  'fridge',       '#EDEDED',  1),
  ('Retro ''58 Refrigerator',      'Rounded retro styling in mint, 7 cu. ft., chrome handles and a quiet inverter compressor.',   45990.00, 'Refrigeration', 2,  'fridge',       '#A8E6CF',  2),
  ('Aqua 8 kg Front-Load Washer',  '15 wash programs, steam hygiene cycle and a 1,200 rpm spin.',                                 21490.00, 'Laundry',       5,  'washer',       '#F2F2F2',  3),
  ('Aqua 10 kg Inverter Washer',   'Big-family capacity with direct-drive inverter motor and quick 15-minute wash.',              32500.00, 'Laundry',       3,  'washer',       '#4A4F5A',  4),
  ('Glow 25 L Microwave',          '900 W microwave with 8 auto-cook menus and a child lock.',                                     4995.00, 'Kitchen',      14,  'microwave',    '#C9CDD3',  5),
  ('Glow Retro Microwave',         'Coral retro microwave with a chrome dial and defrost-by-weight.',                             7490.00, 'Kitchen',       8,  'microwave',    '#FF8A65',  6),
  ('Puff 1.8 L Rice Cooker',       'Cooks 10 cups, keep-warm for 12 hours, non-stick inner pot.',                                 1895.00, 'Kitchen',      25,  'rice_cooker',  '#F3E6C8',  7),
  ('Puff IH Rice Cooker',          'Induction heating for evenly cooked rice, with brown-rice and congee modes.',                 4250.00, 'Kitchen',       9,  'rice_cooker',  '#E5484D',  8),
  ('Whirl Pro Blender',            '1,200 W blender with a 1.5 L jar that crushes ice for shakes in seconds.',                    3490.00, 'Kitchen',      12,  'blender',      '#C8FF2E',  9),
  ('Whirl Mini Blender',           'Compact 600 W blender for smoothies and sauces.',                                             1890.00, 'Kitchen',      20,  'blender',      '#C3B1E1', 10),
  ('Crisp 4 L Air Fryer',          'Crispy fries with 85% less oil; 8 presets and a dishwasher-safe basket.',                     3295.00, 'Kitchen',      18,  'air_fryer',    '#4A4F5A', 11),
  ('Crisp Duo 7 L Air Fryer',      'Family-size basket with a viewing light and shake reminder.',                                 6495.00, 'Kitchen',       7,  'air_fryer',    '#F2F2F2', 12),
  ('Pop 2-Slice Toaster',          'Six browning levels, bagel and defrost buttons, removable crumb tray.',                       1290.00, 'Kitchen',      22,  'toaster',      '#FFE08A', 13),
  ('Pop 4-Slice Toaster',          'Brushed steel toaster with independent slots for the whole family.',                          2450.00, 'Kitchen',      10,  'toaster',      '#C9CDD3', 14),
  ('Boil 1.7 L Kettle',            'Boils a full kettle in about four minutes, with an LED ring that glows while heating.',       1190.00, 'Kitchen',      30,  'kettle',       '#9AD1FF', 15),
  ('Boil Temp-Control Kettle',     'Five temperature presets for coffee and tea, with keep-warm.',                                2190.00, 'Kitchen',       0,  'kettle',       '#E7C9A9', 16),
  ('Breeze 16" Stand Fan',         'Three speeds, wide oscillation and a 7.5-hour timer.',                                        1495.00, 'Cooling',      40,  'fan',          '#F2F2F2', 17),
  ('Breeze Turbo Stand Fan',       'DC motor with 12 quiet speeds and a remote control.',                                         2990.00, 'Cooling',      15,  'fan',          '#5CE1E6', 18),
  ('Arctic 1 HP Split Aircon',     'Inverter split-type for rooms up to 15 m², with a sleep mode and an auto-swing flap.',       24990.00, 'Cooling',       4,  'aircon',       '#F5F5F5', 19),
  ('Arctic 2 HP Inverter Aircon',  'Cools living rooms up to 30 m², with Wi-Fi control and a self-clean cycle.',                 38500.00, 'Cooling',       2,  'aircon',       '#DDE3EA', 20),
  ('Vivid 43" Smart TV',           'Full HD smart TV with built-in streaming apps and a slim bezel.',                            15990.00, 'Entertainment', 11, 'tv',           '#3A3D45', 21),
  ('Vivid 65" 4K Smart TV',        '4K HDR panel, Dolby Audio and voice remote.',                                                54990.00, 'Entertainment', 3,  'tv',           '#C9CDD3', 22),
  ('Roam S1 Robot Vacuum',         'Gyro navigation, 120-minute runtime and app scheduling.',                                     9990.00, 'Cleaning',     13,  'robot_vacuum', '#F2F2F2', 23),
  ('Roam S2 Max Robot Vacuum',     'Lidar mapping, vacuum and mop in one, with auto-empty dock support.',                        19990.00, 'Cleaning',      6,  'robot_vacuum', '#4A4F5A', 24)
) as v(name, description, price, category, stock, model, color, age)
join public.categories c on c.name = v.category
where not exists (select 1 from public.products);
