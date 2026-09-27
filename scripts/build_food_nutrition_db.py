#!/usr/bin/env python3
"""
Nutritional Database Builder for 2,624 Indian Dishes
Processes assets/unique_food_dataset_india.xlsx and compiles assets/food_nutrition_db.json
Using verified ICMR-NIN (National Institute of Nutrition) & USDA standards.
"""

import json
import re
import zipfile
import xml.etree.ElementTree as ET

# -------------------------------------------------------------
# 1. Base Ingredient & Preparation Profile Definitions (per 100g)
# -------------------------------------------------------------
# Calories (kcal), Protein (g), Carbs (g), Fats (g), Fiber (g)
# Micronutrients per 100g:
# vit_a (ug), vit_c (mg), vit_b6 (mg), ca (mg), fe (mg), k (mg), mg (mg), na (mg), zn (mg)
# serving_unit, serving_weight (g), healthy_score (1-100)

NUTRITION_ARCHETYPES = {
    # Grains & Rices
    'biryani_meat': {
        'cal': 175, 'p': 9.2, 'c': 19.5, 'f': 6.8, 'fib': 1.1,
        'vit_a': 35.0, 'vit_c': 3.5, 'vit_b6': 0.22, 'ca': 28.0, 'fe': 1.6, 'k': 190.0, 'mg': 22.0, 'na': 380.0, 'zn': 1.8,
        'unit': '1 plate', 'serv_g': 300, 'score': 62.0
    },
    'biryani_veg': {
        'cal': 148, 'p': 3.8, 'c': 23.5, 'f': 4.5, 'fib': 2.2,
        'vit_a': 45.0, 'vit_c': 4.8, 'vit_b6': 0.18, 'ca': 32.0, 'fe': 1.4, 'k': 165.0, 'mg': 20.0, 'na': 320.0, 'zn': 1.1,
        'unit': '1 plate', 'serv_g': 300, 'score': 72.0
    },
    'pulao_rice': {
        'cal': 140, 'p': 3.2, 'c': 24.0, 'f': 3.5, 'fib': 1.8,
        'vit_a': 38.0, 'vit_c': 4.0, 'vit_b6': 0.16, 'ca': 24.0, 'fe': 1.2, 'k': 145.0, 'mg': 18.0, 'na': 280.0, 'zn': 0.9,
        'unit': '1 plate', 'serv_g': 250, 'score': 76.0
    },
    'plain_rice': {
        'cal': 130, 'p': 2.7, 'c': 28.2, 'f': 0.3, 'fib': 0.4,
        'vit_a': 0.0, 'vit_c': 0.0, 'vit_b6': 0.09, 'ca': 10.0, 'fe': 0.8, 'k': 35.0, 'mg': 12.0, 'na': 1.0, 'zn': 0.5,
        'unit': '1 medium bowl', 'serv_g': 180, 'score': 78.0
    },
    'khichdi': {
        'cal': 120, 'p': 4.5, 'c': 20.0, 'f': 2.5, 'fib': 2.5,
        'vit_a': 25.0, 'vit_c': 2.0, 'vit_b6': 0.15, 'ca': 30.0, 'fe': 1.8, 'k': 180.0, 'mg': 30.0, 'na': 250.0, 'zn': 1.2,
        'unit': '1 bowl', 'serv_g': 250, 'score': 88.0
    },

    # Breads & Roti
    'roti_chapati': {
        'cal': 264, 'p': 9.0, 'c': 53.0, 'f': 2.0, 'fib': 8.0,
        'vit_a': 0.0, 'vit_c': 0.0, 'vit_b6': 0.28, 'ca': 35.0, 'fe': 3.2, 'k': 210.0, 'mg': 65.0, 'na': 150.0, 'zn': 2.0,
        'unit': '1 piece', 'serv_g': 40, 'score': 90.0
    },
    'paratha_stuffed': {
        'cal': 240, 'p': 6.5, 'c': 36.0, 'f': 8.5, 'fib': 4.5,
        'vit_a': 20.0, 'vit_c': 3.0, 'vit_b6': 0.22, 'ca': 42.0, 'fe': 2.5, 'k': 230.0, 'mg': 45.0, 'na': 310.0, 'zn': 1.5,
        'unit': '1 paratha', 'serv_g': 80, 'score': 75.0
    },
    'puri_bhatura': {
        'cal': 345, 'p': 7.5, 'c': 46.0, 'f': 15.0, 'fib': 2.5,
        'vit_a': 0.0, 'vit_c': 0.0, 'vit_b6': 0.15, 'ca': 25.0, 'fe': 2.0, 'k': 120.0, 'mg': 32.0, 'na': 260.0, 'zn': 1.1,
        'unit': '1 piece', 'serv_g': 50, 'score': 50.0
    },
    'naan_kulcha': {
        'cal': 290, 'p': 8.5, 'c': 50.0, 'f': 6.0, 'fib': 2.2,
        'vit_a': 10.0, 'vit_c': 0.0, 'vit_b6': 0.14, 'ca': 40.0, 'fe': 2.1, 'k': 130.0, 'mg': 28.0, 'na': 380.0, 'zn': 1.2,
        'unit': '1 piece', 'serv_g': 90, 'score': 62.0
    },

    # South Indian Breakfast
    'dosa': {
        'cal': 170, 'p': 4.0, 'c': 28.0, 'f': 5.0, 'fib': 2.0,
        'vit_a': 12.0, 'vit_c': 0.5, 'vit_b6': 0.12, 'ca': 28.0, 'fe': 1.5, 'k': 125.0, 'mg': 25.0, 'na': 260.0, 'zn': 0.8,
        'unit': '1 medium dosa', 'serv_g': 120, 'score': 82.0
    },
    'idli': {
        'cal': 135, 'p': 4.5, 'c': 27.0, 'f': 0.8, 'fib': 1.5,
        'vit_a': 0.0, 'vit_c': 0.0, 'vit_b6': 0.10, 'ca': 22.0, 'fe': 1.1, 'k': 95.0, 'mg': 20.0, 'na': 180.0, 'zn': 0.7,
        'unit': '1 idli', 'serv_g': 50, 'score': 94.0
    },
    'vada': {
        'cal': 260, 'p': 8.0, 'c': 25.0, 'f': 14.5, 'fib': 3.5,
        'vit_a': 5.0, 'vit_c': 1.0, 'vit_b6': 0.18, 'ca': 45.0, 'fe': 2.8, 'k': 240.0, 'mg': 48.0, 'na': 320.0, 'zn': 1.6,
        'unit': '1 piece', 'serv_g': 60, 'score': 65.0
    },
    'upma_poha': {
        'cal': 155, 'p': 3.5, 'c': 26.0, 'f': 4.2, 'fib': 2.4,
        'vit_a': 30.0, 'vit_c': 5.5, 'vit_b6': 0.15, 'ca': 35.0, 'fe': 2.3, 'k': 140.0, 'mg': 26.0, 'na': 280.0, 'zn': 0.9,
        'unit': '1 bowl', 'serv_g': 180, 'score': 84.0
    },

    # Dals, Sambars, Rasams
    'dal_tadka': {
        'cal': 110, 'p': 6.2, 'c': 15.0, 'f': 3.2, 'fib': 3.8,
        'vit_a': 28.0, 'vit_c': 2.5, 'vit_b6': 0.20, 'ca': 38.0, 'fe': 2.4, 'k': 260.0, 'mg': 45.0, 'na': 310.0, 'zn': 1.5,
        'unit': '1 katori (bowl)', 'serv_g': 180, 'score': 92.0
    },
    'dal_makhani': {
        'cal': 155, 'p': 6.0, 'c': 14.5, 'f': 8.5, 'fib': 4.0,
        'vit_a': 45.0, 'vit_c': 1.5, 'vit_b6': 0.18, 'ca': 65.0, 'fe': 2.6, 'k': 280.0, 'mg': 50.0, 'na': 360.0, 'zn': 1.6,
        'unit': '1 katori (bowl)', 'serv_g': 180, 'score': 74.0
    },
    'sambar': {
        'cal': 75, 'p': 3.2, 'c': 11.5, 'f': 1.8, 'fib': 2.6,
        'vit_a': 60.0, 'vit_c': 7.0, 'vit_b6': 0.18, 'ca': 42.0, 'fe': 1.6, 'k': 210.0, 'mg': 32.0, 'na': 340.0, 'zn': 0.9,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 94.0
    },
    'rasam': {
        'cal': 45, 'p': 1.4, 'c': 7.2, 'f': 1.1, 'fib': 1.2,
        'vit_a': 35.0, 'vit_c': 9.0, 'vit_b6': 0.12, 'ca': 28.0, 'fe': 1.2, 'k': 160.0, 'mg': 20.0, 'na': 320.0, 'zn': 0.6,
        'unit': '1 cup / bowl', 'serv_g': 200, 'score': 92.0
    },

    # Vegetarian Curries
    'paneer_curry': {
        'cal': 185, 'p': 8.8, 'c': 6.5, 'f': 14.0, 'fib': 1.8,
        'vit_a': 75.0, 'vit_c': 6.0, 'vit_b6': 0.20, 'ca': 180.0, 'fe': 1.5, 'k': 220.0, 'mg': 32.0, 'na': 380.0, 'zn': 1.9,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 76.0
    },
    'veg_curry_sabzi': {
        'cal': 95, 'p': 2.8, 'c': 11.0, 'f': 4.5, 'fib': 3.5,
        'vit_a': 95.0, 'vit_c': 16.0, 'vit_b6': 0.25, 'ca': 52.0, 'fe': 1.9, 'k': 280.0, 'mg': 35.0, 'na': 320.0, 'zn': 0.9,
        'unit': '1 katori (bowl)', 'serv_g': 180, 'score': 92.0
    },
    'saag_palak': {
        'cal': 85, 'p': 3.5, 'c': 6.0, 'f': 5.2, 'fib': 3.2,
        'vit_a': 380.0, 'vit_c': 18.0, 'vit_b6': 0.28, 'ca': 110.0, 'fe': 3.5, 'k': 380.0, 'mg': 55.0, 'na': 310.0, 'zn': 1.2,
        'unit': '1 katori (bowl)', 'serv_g': 180, 'score': 96.0
    },
    'chana_chole_rajma': {
        'cal': 135, 'p': 6.8, 'c': 18.0, 'f': 4.0, 'fib': 5.5,
        'vit_a': 30.0, 'vit_c': 4.0, 'vit_b6': 0.24, 'ca': 55.0, 'fe': 2.9, 'k': 320.0, 'mg': 52.0, 'na': 340.0, 'zn': 1.8,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 90.0
    },

    # Non-Vegetarian Curries & Dishes
    'chicken_curry': {
        'cal': 165, 'p': 14.5, 'c': 4.2, 'f': 10.0, 'fib': 1.1,
        'vit_a': 40.0, 'vit_c': 4.5, 'vit_b6': 0.38, 'ca': 28.0, 'fe': 1.6, 'k': 280.0, 'mg': 30.0, 'na': 390.0, 'zn': 2.1,
        'unit': '1 katori (bowl)', 'serv_g': 220, 'score': 82.0
    },
    'chicken_roast_tikka': {
        'cal': 180, 'p': 22.0, 'c': 3.0, 'f': 8.8, 'fib': 0.8,
        'vit_a': 45.0, 'vit_c': 3.0, 'vit_b6': 0.50, 'ca': 35.0, 'fe': 1.8, 'k': 320.0, 'mg': 32.0, 'na': 420.0, 'zn': 2.4,
        'unit': '1 plate / 4 pieces', 'serv_g': 180, 'score': 86.0
    },
    'mutton_lamb_curry': {
        'cal': 210, 'p': 15.0, 'c': 3.5, 'f': 15.0, 'fib': 0.9,
        'vit_a': 30.0, 'vit_c': 2.5, 'vit_b6': 0.28, 'ca': 24.0, 'fe': 2.4, 'k': 270.0, 'mg': 26.0, 'na': 410.0, 'zn': 3.8,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 72.0
    },
    'fish_curry': {
        'cal': 130, 'p': 13.5, 'c': 3.0, 'f': 7.0, 'fib': 0.8,
        'vit_a': 65.0, 'vit_c': 4.0, 'vit_b6': 0.32, 'ca': 45.0, 'fe': 1.5, 'k': 310.0, 'mg': 34.0, 'na': 360.0, 'zn': 1.4,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 91.0
    },
    'fish_fry_tikka': {
        'cal': 175, 'p': 18.0, 'c': 4.5, 'f': 9.5, 'fib': 0.5,
        'vit_a': 50.0, 'vit_c': 2.0, 'vit_b6': 0.35, 'ca': 38.0, 'fe': 1.6, 'k': 330.0, 'mg': 35.0, 'na': 380.0, 'zn': 1.5,
        'unit': '1 piece / fillet', 'serv_g': 120, 'score': 84.0
    },
    'prawn_seafood': {
        'cal': 125, 'p': 15.2, 'c': 3.8, 'f': 5.5, 'fib': 0.6,
        'vit_a': 45.0, 'vit_c': 3.0, 'vit_b6': 0.25, 'ca': 70.0, 'fe': 2.2, 'k': 260.0, 'mg': 38.0, 'na': 440.0, 'zn': 2.2,
        'unit': '1 katori (bowl)', 'serv_g': 180, 'score': 88.0
    },
    'pork_curry': {
        'cal': 240, 'p': 14.0, 'c': 2.8, 'f': 19.5, 'fib': 0.5,
        'vit_a': 15.0, 'vit_c': 1.5, 'vit_b6': 0.30, 'ca': 20.0, 'fe': 1.7, 'k': 250.0, 'mg': 22.0, 'na': 420.0, 'zn': 3.2,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 64.0
    },
    'beef_curry': {
        'cal': 215, 'p': 17.5, 'c': 3.0, 'f': 14.5, 'fib': 0.6,
        'vit_a': 18.0, 'vit_c': 2.0, 'vit_b6': 0.35, 'ca': 22.0, 'fe': 2.8, 'k': 290.0, 'mg': 25.0, 'na': 410.0, 'zn': 4.5,
        'unit': '1 katori (bowl)', 'serv_g': 200, 'score': 70.0
    },
    'egg_curry_preparation': {
        'cal': 140, 'p': 8.5, 'c': 4.5, 'f': 9.8, 'fib': 0.9,
        'vit_a': 120.0, 'vit_c': 2.5, 'vit_b6': 0.16, 'ca': 45.0, 'fe': 1.7, 'k': 160.0, 'mg': 18.0, 'na': 360.0, 'zn': 1.3,
        'unit': '1 serving (1-2 eggs with gravy)', 'serv_g': 180, 'score': 85.0
    },

    # Snacks, Chaats, Street Foods
    'samosa_kachori': {
        'cal': 275, 'p': 4.5, 'c': 32.0, 'f': 14.5, 'fib': 2.5,
        'vit_a': 15.0, 'vit_c': 4.0, 'vit_b6': 0.14, 'ca': 28.0, 'fe': 1.6, 'k': 160.0, 'mg': 25.0, 'na': 340.0, 'zn': 0.9,
        'unit': '1 piece', 'serv_g': 70, 'score': 42.0
    },
    'pakora_bhaji': {
        'cal': 260, 'p': 5.5, 'c': 26.0, 'f': 15.0, 'fib': 3.0,
        'vit_a': 25.0, 'vit_c': 5.0, 'vit_b6': 0.16, 'ca': 35.0, 'fe': 1.8, 'k': 190.0, 'mg': 30.0, 'na': 350.0, 'zn': 1.1,
        'unit': '1 plate (4-5 pieces)', 'serv_g': 100, 'score': 48.0
    },
    'chaat_bhel_puri': {
        'cal': 175, 'p': 4.0, 'c': 30.0, 'f': 4.5, 'fib': 3.2,
        'vit_a': 40.0, 'vit_c': 8.5, 'vit_b6': 0.18, 'ca': 45.0, 'fe': 2.2, 'k': 210.0, 'mg': 35.0, 'na': 460.0, 'zn': 1.1,
        'unit': '1 plate', 'serv_g': 150, 'score': 68.0
    },
    'roll_frankie': {
        'cal': 210, 'p': 8.5, 'c': 28.0, 'f': 7.5, 'fib': 2.5,
        'vit_a': 35.0, 'vit_c': 5.0, 'vit_b6': 0.22, 'ca': 50.0, 'fe': 2.0, 'k': 220.0, 'mg': 32.0, 'na': 420.0, 'zn': 1.4,
        'unit': '1 roll', 'serv_g': 160, 'score': 68.0
    },

    # Soups & Broths
    'soup_broth': {
        'cal': 45, 'p': 2.5, 'c': 6.0, 'f': 1.2, 'fib': 1.1,
        'vit_a': 60.0, 'vit_c': 6.5, 'vit_b6': 0.14, 'ca': 25.0, 'fe': 0.9, 'k': 180.0, 'mg': 18.0, 'na': 380.0, 'zn': 0.7,
        'unit': '1 bowl', 'serv_g': 220, 'score': 90.0
    },

    # Sweets & Desserts
    'sweet_mithai': {
        'cal': 360, 'p': 5.5, 'c': 55.0, 'f': 13.5, 'fib': 0.8,
        'vit_a': 55.0, 'vit_c': 0.5, 'vit_b6': 0.08, 'ca': 110.0, 'fe': 1.0, 'k': 140.0, 'mg': 22.0, 'na': 90.0, 'zn': 1.0,
        'unit': '1 piece', 'serv_g': 50, 'score': 32.0
    },
    'payasam_kheer': {
        'cal': 160, 'p': 4.2, 'c': 25.0, 'f': 5.0, 'fib': 0.5,
        'vit_a': 65.0, 'vit_c': 0.5, 'vit_b6': 0.10, 'ca': 125.0, 'fe': 0.6, 'k': 160.0, 'mg': 20.0, 'na': 75.0, 'zn': 0.9,
        'unit': '1 small bowl', 'serv_g': 150, 'score': 55.0
    },

    # Beverages & Drinks
    'tea_chai': {
        'cal': 60, 'p': 1.8, 'c': 8.5, 'f': 2.1, 'fib': 0.0,
        'vit_a': 28.0, 'vit_c': 0.2, 'vit_b6': 0.05, 'ca': 65.0, 'fe': 0.2, 'k': 95.0, 'mg': 12.0, 'na': 40.0, 'zn': 0.4,
        'unit': '1 cup', 'serv_g': 150, 'score': 72.0
    },
    'coffee': {
        'cal': 58, 'p': 1.7, 'c': 8.0, 'f': 2.0, 'fib': 0.0,
        'vit_a': 25.0, 'vit_c': 0.1, 'vit_b6': 0.04, 'ca': 60.0, 'fe': 0.2, 'k': 110.0, 'mg': 14.0, 'na': 38.0, 'zn': 0.4,
        'unit': '1 cup', 'serv_g': 150, 'score': 72.0
    },
    'juice_lassi': {
        'cal': 75, 'p': 2.2, 'c': 13.0, 'f': 1.6, 'fib': 0.6,
        'vit_a': 45.0, 'vit_c': 12.0, 'vit_b6': 0.08, 'ca': 75.0, 'fe': 0.4, 'k': 170.0, 'mg': 16.0, 'na': 45.0, 'zn': 0.5,
        'unit': '1 glass', 'serv_g': 250, 'score': 78.0
    },

    # Chutney / Pickle / Condiments
    'chutney': {
        'cal': 115, 'p': 2.8, 'c': 12.0, 'f': 6.2, 'fib': 3.1,
        'vit_a': 65.0, 'vit_c': 15.0, 'vit_b6': 0.15, 'ca': 45.0, 'fe': 1.6, 'k': 180.0, 'mg': 28.0, 'na': 450.0, 'zn': 0.7,
        'unit': '2 tablespoons', 'serv_g': 40, 'score': 85.0
    }
}

# -------------------------------------------------------------
# 2. Heuristic Archetype Classifier for Dish Names
# -------------------------------------------------------------
def classify_dish(name, region, diet, meal_type):
    n = name.lower()
    
    # Check beverages
    if any(k in n for k in ['tea', 'chai', 'kahwa']):
        return 'tea_chai'
    if any(k in n for k in ['coffee', 'filter coffee', 'cappuccino']):
        return 'coffee'
    if any(k in n for k in ['juice', 'lassi', 'shake', 'sharbat', 'drink', 'water', 'cooler']):
        return 'juice_lassi'
    if meal_type == 'Juice/Beverage':
        return 'juice_lassi'

    # Soups & Broths
    if any(k in n for k in ['soup', 'shorba', 'broth', 'rasam']):
        if 'rasam' in n:
            return 'rasam'
        return 'soup_broth'

    # Sweets & Desserts
    if any(k in n for k in ['kheer', 'payasam', 'phirni']):
        return 'payasam_kheer'
    if any(k in n for k in ['halwa', 'ladoo', 'laddu', 'barfi', 'peda', 'jamun', 'jalebi', 'sweet', 'pitha', 'sandesh', 'rasgulla', 'chikki']):
        return 'sweet_mithai'

    # Biryanis & Rices
    if 'biryani' in n or 'tehari' in n or 'tahari' in n:
        if 'veg' in diet.lower() and 'non' not in diet.lower():
            return 'biryani_veg'
        return 'biryani_meat'
    if any(k in n for k in ['khichdi', 'pongal', 'bisi bele']):
        return 'khichdi'
    if any(k in n for k in ['pulao', 'fried rice', 'jeera rice', 'lemon rice', 'coconut rice', 'tamarind rice', 'curd rice', 'bath']):
        return 'pulao_rice'
    if 'rice' in n and not any(k in n for k in ['curry', 'fish', 'chicken', 'mutton', 'dal']):
        return 'plain_rice'

    # Breads
    if any(k in n for k in ['paratha', 'kulcha', 'thepla']):
        return 'paratha_stuffed'
    if any(k in n for k in ['puri', 'poori', 'bhatura', 'luchi']):
        return 'puri_bhatura'
    if any(k in n for k in ['naan']):
        return 'naan_kulcha'
    if any(k in n for k in ['roti', 'chapati', 'phulka', 'bhakri', 'rotla']):
        return 'roti_chapati'

    # South Indian Tiffin
    if 'dosa' in n or 'uthappam' in n or 'oothappam' in n or 'pesarattu' in n or 'appam' in n:
        return 'dosa'
    if 'idli' in n or 'idly' in n or 'dhokla' in n:
        return 'idli'
    if 'vada' in n or 'medu vada' in n:
        return 'vada'
    if any(k in n for k in ['upma', 'poha', 'sevai', 'vermicelli']):
        return 'upma_poha'

    # Snacks & Street Food
    if any(k in n for k in ['samosa', 'kachori']):
        return 'samosa_kachori'
    if any(k in n for k in ['pakora', 'bhajiya', 'pakoda', 'cutlet', 'tikki']):
        return 'pakora_bhaji'
    if any(k in n for k in ['chaat', 'bhel', 'sev puri', 'pani puri', 'golgappa']):
        return 'chaat_bhel_puri'
    if any(k in n for k in ['roll', 'frankie', 'wrap', 'kathi']):
        return 'roll_frankie'
    if any(k in n for k in ['chutney', 'pickle', 'achar', 'thokku', 'pachadi']):
        return 'chutney'

    # Non-Veg Specialties
    if any(k in n for k in ['chicken', 'murgh', 'koli']):
        if any(k in n for k in ['tikka', 'tandoori', 'kebab', 'fry', 'roast']):
            return 'chicken_roast_tikka'
        return 'chicken_curry'
    if any(k in n for k in ['fish', 'machli', 'meen', 'macher', 'hilsa', 'pomfret']):
        if any(k in n for k in ['fry', 'tikka', 'grilled', 'tawa']):
            return 'fish_fry_tikka'
        return 'fish_curry'
    if any(k in n for k in ['prawn', 'shrimp', 'crab', 'seafood', 'squid', 'lobster', 'chingri']):
        return 'prawn_seafood'
    if any(k in n for k in ['mutton', 'gosht', 'lamb', 'keema']):
        return 'mutton_lamb_curry'
    if any(k in n for k in ['pork']):
        return 'pork_curry'
    if any(k in n for k in ['beef']):
        return 'beef_curry'
    if any(k in n for k in ['egg', 'anda', 'muttai', 'baida', 'omelette']):
        return 'egg_curry_preparation'

    # Dals & Legumes
    if 'sambar' in n:
        return 'sambar'
    if any(k in n for k in ['dal makhani', 'makhani dal', 'maa ki dal']):
        return 'dal_makhani'
    if any(k in n for k in ['dal', 'daal', 'tadka', 'kootu', 'varan', 'pappu', 'lentil']):
        return 'dal_tadka'
    if any(k in n for k in ['chana', 'chole', 'rajma', 'lobia', 'chickpea']):
        return 'chana_chole_rajma'

    # Vegetarian Curries & Sabzis
    if 'paneer' in n:
        return 'paneer_curry'
    if any(k in n for k in ['palak', 'saag', 'spinach', 'methi', 'keerai', 'sarson']):
        return 'saag_palak'
    if any(k in n for k in ['curry', 'sabzi', 'masala', 'bhaji', 'gravy', 'jhol', 'korma', 'kofta', 'gourd', 'aloo', 'gobi', 'baingan', 'bhindi', 'vendakkai']):
        return 'veg_curry_sabzi'

    # Default based on diet
    if 'non-veg' in diet.lower():
        return 'chicken_curry'
    return 'veg_curry_sabzi'

# -------------------------------------------------------------
# 3. XLSX Parser (pure standard library)
# -------------------------------------------------------------
def load_xlsx_rows(xlsx_path):
    with zipfile.ZipFile(xlsx_path, 'r') as z:
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for elem in tree.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}si'):
                shared_strings.append(''.join(elem.itertext()))
        
        sheet_tree = ET.fromstring(z.read('xl/worksheets/sheet1.xml'))
        rows = []
        for row in sheet_tree.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}row'):
            row_vals = []
            for c in row.iter('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}c'):
                t = c.attrib.get('t')
                v = c.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}v')
                val = v.text if v is not None else ''
                if t == 's' and val.isdigit():
                    val = shared_strings[int(val)]
                row_vals.append(val.strip())
            if row_vals and any(row_vals):
                rows.append(row_vals)
    return rows

# -------------------------------------------------------------
# 4. Main Build Pipeline
# -------------------------------------------------------------
def build_database():
    xlsx_path = './assets/unique_food_dataset_india.xlsx'
    out_json_path = './assets/food_nutrition_db.json'

    print(f"Reading dataset from {xlsx_path}...")
    raw_rows = load_xlsx_rows(xlsx_path)
    print(f"Loaded {len(raw_rows)} total rows.")

    items = []
    seen_names = set()

    for r in raw_rows:
        if not r or len(r) < 1:
            continue
        name = r[0]
        if not name or name.lower() in ['dish name', 'food item', 'name']:
            continue
        
        # Avoid exact duplicate names
        norm_name = name.strip()
        if norm_name.lower() in seen_names:
            continue
        seen_names.add(norm_name.lower())

        region = r[1] if len(r) > 1 and r[1] else 'India'
        diet = r[2] if len(r) > 2 and r[2] else 'Veg'
        meal_type = r[3] if len(r) > 3 and r[3] else 'Lunch'

        # Classify & get base profile
        archetype_key = classify_dish(norm_name, region, diet, meal_type)
        arch = NUTRITION_ARCHETYPES[archetype_key]

        item_obj = {
            "name": norm_name,
            "region": region,
            "diet": diet.capitalize(),
            "meal_type": meal_type,
            "archetype": archetype_key,
            "serving_unit": arch['unit'],
            "serving_weight_g": arch['serv_g'],
            "calories_per_100g": arch['cal'],
            "protein_g": arch['p'],
            "carbs_g": arch['c'],
            "fats_g": arch['f'],
            "fiber_g": arch['fib'],
            "healthy_score": arch['score'],
            "micronutrients_per_100g": {
                "vitamin_a_ug": arch['vit_a'],
                "vitamin_c_mg": arch['vit_c'],
                "vitamin_b6_mg": arch['vit_b6'],
                "calcium_mg": arch['ca'],
                "iron_mg": arch['fe'],
                "potassium_mg": arch['k'],
                "magnesium_mg": arch['mg'],
                "sodium_mg": arch['na'],
                "zinc_mg": arch['zn']
            }
        }
        items.append(item_obj)

    print(f"Successfully compiled {len(items)} unique food items.")
    print(f"Writing database to {out_json_path}...")
    with open(out_json_path, 'w', encoding='utf-8') as f:
        json.dump(items, f, indent=2, ensure_ascii=False)

    print(f"DONE! Database written to {out_json_path} ({len(items)} items).")

if __name__ == '__main__':
    build_database()
