import 'package:flutter/material.dart';

import '../models/product.dart';

/// HomeHub's appliance catalog. Photos are loaded from stable Unsplash URLs.
const List<Product> products = [
  Product(
    id: 'p1',
    name: 'Compact Refrigerator',
    category: 'Kitchen',
    brand: 'Panasonic',
    price: 249.99,
    description:
        'A space-saving refrigerator with adjustable shelves and a quiet, energy-efficient cooling system.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/6/61/Panasonic_HOME_REFRIGERATOR_NR-C320WP-N.jpg/960px-Panasonic_HOME_REFRIGERATOR_NR-C320WP-N.jpg',
    fallbackIcon: Icons.kitchen_rounded,
    rating: 4.9,
    sold: 1200,
    discountPercent: 18,
  ),
  Product(
    id: 'p2',
    name: 'Front-Load Washing Machine',
    category: 'Laundry',
    brand: 'Fagor',
    price: 499.00,
    description:
        'Gentle, efficient cleaning with multiple wash programs and a generous front-loading drum.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/ba/Fagor_washing_machine_front_FF6314.jpg/960px-Fagor_washing_machine_front_FF6314.jpg',
    fallbackIcon: Icons.local_laundry_service_rounded,
    rating: 4.8,
    sold: 860,
    discountPercent: 12,
  ),
  Product(
    id: 'p3',
    name: 'Countertop Microwave',
    category: 'Kitchen',
    brand: 'HomeHub Select',
    price: 89.99,
    description:
        'Quickly reheat meals with simple controls, even cooking, and a compact footprint for smaller kitchens.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/4/4e/Microwave_oven.jpg/960px-Microwave_oven.jpg',
    fallbackIcon: Icons.microwave_rounded,
    rating: 4.7,
    sold: 2300,
    discountPercent: 25,
  ),
  Product(
    id: 'p4',
    name: 'Split-Type Air Conditioner',
    category: 'Climate',
    brand: 'Panasonic',
    price: 399.50,
    description:
        'Bring comfortable, consistent cooling to your room with quiet operation and smart temperature control.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/eb/Panasonic_AIR_CONDITIONER_INDOOR_UNIT_CS-C10KJ2_%282%29.jpg/960px-Panasonic_AIR_CONDITIONER_INDOOR_UNIT_CS-C10KJ2_%282%29.jpg',
    fallbackIcon: Icons.ac_unit_rounded,
    rating: 4.6,
    sold: 540,
    discountPercent: 10,
  ),
  Product(
    id: 'p5',
    name: 'Personal Blender',
    category: 'Kitchen',
    brand: 'NutriBullet',
    price: 34.99,
    description:
        'Blend smoothies and sauces directly into a travel cup with a compact motor made for everyday use.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/2/2f/Magic_Bullet_and_Nutribullet_Blenders.jpg/960px-Magic_Bullet_and_Nutribullet_Blenders.jpg',
    fallbackIcon: Icons.blender_rounded,
    rating: 4.8,
    sold: 3100,
    discountPercent: 30,
  ),
  Product(
    id: 'p6',
    name: 'Electric Kettle',
    category: 'Kitchen',
    brand: 'Bosch',
    price: 24.99,
    description:
        'Boil water quickly and safely with automatic shutoff, a clear water window, and a cordless base.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/3/3e/2023_Czajnik_elektryczny_Bosch_%281%29.jpg/960px-2023_Czajnik_elektryczny_Bosch_%281%29.jpg',
    fallbackIcon: Icons.coffee_rounded,
    rating: 4.9,
    sold: 4500,
    discountPercent: 20,
  ),
  Product(
    id: 'p7',
    name: 'Cordless Vacuum Cleaner',
    category: 'Cleaning',
    brand: 'Bosch',
    price: 149.99,
    description:
        'A lightweight cordless vacuum with strong everyday suction for floors, furniture, and tight corners.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/f/f7/Cordless_vacuum_cleaner_in_the_kitchen_closeup.jpg/960px-Cordless_vacuum_cleaner_in_the_kitchen_closeup.jpg',
    fallbackIcon: Icons.cleaning_services_rounded,
    rating: 4.7,
    sold: 980,
    discountPercent: 15,
  ),
  Product(
    id: 'p8',
    name: '2-Slice Toaster',
    category: 'Kitchen',
    brand: 'HomeHub Select',
    price: 29.99,
    description:
        'Crisp toast your way with adjustable browning levels, a cancel button, and a removable crumb tray.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/8/8f/Toaster.jpg/960px-Toaster.jpg',
    fallbackIcon: Icons.breakfast_dining_rounded,
    rating: 4.6,
    sold: 1800,
    discountPercent: 22,
  ),
  Product(
    id: 'p9',
    name: 'Smart Rice Cooker',
    category: 'Kitchen',
    brand: 'Panasonic',
    price: 54.99,
    description:
        'Cook fluffy rice, grains, and steamed vegetables with one-touch programs and a keep-warm setting.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/5/5f/Panasonic_RICE_COOKER_SR-L15H8.jpg/960px-Panasonic_RICE_COOKER_SR-L15H8.jpg',
    fallbackIcon: Icons.rice_bowl_rounded,
    rating: 4.8,
    sold: 2700,
    discountPercent: 16,
  ),
  Product(
    id: 'p10',
    name: 'Digital Air Fryer',
    category: 'Kitchen',
    brand: 'Philips',
    price: 74.99,
    description:
        'Make crispy favorites with less oil using preset cooking modes and an easy-to-clean non-stick basket.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/e/ef/Airfryer.jpg/960px-Airfryer.jpg',
    fallbackIcon: Icons.outdoor_grill_rounded,
    rating: 4.7,
    sold: 1900,
    discountPercent: 24,
  ),
  Product(
    id: 'p11',
    name: 'Robot Floor Cleaner',
    category: 'Cleaning',
    brand: 'Miele',
    price: 189.99,
    description:
        'Schedule hands-free floor cleaning with smart mapping, strong suction, and a slim design for tight spaces.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/b/bc/Miele_robot_vacuum%2C_IFA_2015.jpg/960px-Miele_robot_vacuum%2C_IFA_2015.jpg',
    fallbackIcon: Icons.smart_toy_rounded,
    rating: 4.6,
    sold: 720,
    discountPercent: 14,
  ),
  Product(
    id: 'p12',
    name: 'Quiet Room Dehumidifier',
    category: 'Climate',
    brand: 'Sharp',
    price: 119.99,
    description:
        'Keep rooms comfortable with quiet moisture control, an easy water tank, and automatic shutoff.',
    imageUrl:
        'https://thumb.wikimedia.org/wikipedia/commons/thumb/a/a4/SHARP_DEHUMIDIFIER_DW-CE15F-W_LEFT_SIDE.jpg/960px-SHARP_DEHUMIDIFIER_DW-CE15F-W_LEFT_SIDE.jpg',
    fallbackIcon: Icons.water_drop_rounded,
    rating: 4.5,
    sold: 430,
    discountPercent: 11,
  ),
];

Product productById(String id) => products.firstWhere(
      (product) => product.id == id,
      orElse: () => products.first,
    );

String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';
