#!/usr/bin/env python3
"""
Build Multi-Country Food Nutrition Database from all-countries/*.xlsx.
Produces categorized JSON files in assets/food_data/ and updates categories_meta.json.
"""

import os
import glob
import json
import openpyxl

ASSETS_DIR = 'assets'
DATA_DIR = os.path.join(ASSETS_DIR, 'food_data')
ALL_COUNTRIES_DIR = 'all-countries'

os.makedirs(DATA_DIR, exist_ok=True)

def safe_float(v, default=0.0):
    if v is None:
        return default
    try:
        # Handle string like '295.4' or '< 0.5'
        s = str(v).replace('<', '').replace('>', '').replace('~', '').strip()
        val = float(s)
        return round(val, 2)
    except:
        return default

def safe_int(v, default=0):
    if v is None:
        return default
    try:
        s = str(v).replace('<', '').replace('>', '').replace('~', '').strip()
        return int(round(float(s)))
    except:
        return default

def compute_health_score(calories, protein, fiber, sodium):
    # Base score 75. Balanced macro rewards, excessive calorie/sodium penalty
    score = 75.0
    if calories > 450:
        score -= min(25.0, (calories - 450) / 20.0)
    elif calories < 150:
        score += 5.0

    if fiber > 3.0:
        score += min(15.0, fiber * 2.0)
    if protein > 10.0:
        score += min(15.0, (protein - 10.0) * 1.5)
    if sodium > 600:
        score -= min(20.0, (sodium - 600) / 50.0)
    return round(max(20.0, min(100.0, score)), 1)

def convert_standard_sheet(filepath, country_name, default_region):
    print(f"Reading {filepath}...")
    wb = openpyxl.load_workbook(filepath, read_only=True)
    sheet = wb.active
    rows = sheet.iter_rows(values_only=True)
    header = [str(c).strip() if c else '' for c in next(rows)]
    
    records = []
    seen = set()

    for r in rows:
        if not r or not r[0]:
            continue
        row_dict = dict(zip(header, r))
        name = str(row_dict.get('Item name', '')).strip()
        if not name or name in seen:
            continue
        seen.add(name)

        region = str(row_dict.get('Region') or default_region).strip()
        diet = str(row_dict.get('Veg/Non-veg') or 'Standard').strip()
        meal = str(row_dict.get('Meal type') or 'Meal').strip()
        typical_serving = str(row_dict.get('Typical serving') or '1 serving').strip()
        serving_weight = safe_int(row_dict.get('Serving weight (g)'), 100)
        if serving_weight <= 0 or serving_weight > 2000:
            serving_weight = 100

        cals = safe_int(row_dict.get('Calories (kcal)'))
        carbs = safe_float(row_dict.get('Carbohydrates (g)'))
        protein = safe_float(row_dict.get('Protein (g)'))
        fats = safe_float(row_dict.get('Fats (g)'))
        fiber = safe_float(row_dict.get('Fiber (g)'))

        vit_a = safe_float(row_dict.get('Vitamin A (µg)'))
        vit_c = safe_float(row_dict.get('Vitamin C (mg)'))
        vit_b6 = safe_float(row_dict.get('Vitamin B6 (mg)'))
        calcium = safe_float(row_dict.get('Calcium (mg)'))
        iron = safe_float(row_dict.get('Iron (mg)'))
        potassium = safe_float(row_dict.get('Potassium (mg)'))
        magnesium = safe_float(row_dict.get('Magnesium (mg)'))
        sodium = safe_float(row_dict.get('Sodium (mg)'))
        zinc = safe_float(row_dict.get('Zinc (mg)'))

        score = compute_health_score(cals, protein, fiber, sodium)

        rec = {
            'name': name,
            'region': region,
            'diet': diet,
            'meal_type': meal,
            'serving_unit': typical_serving,
            'serving_weight_g': serving_weight,
            'calories_per_100g': cals,
            'protein_g': protein,
            'carbs_g': carbs,
            'fats_g': fats,
            'fiber_g': fiber,
            'healthy_score': score,
            'micronutrients_per_100g': {
                'vitamin_a_ug': vit_a,
                'vitamin_c_mg': vit_c,
                'vitamin_b6_mg': vit_b6,
                'calcium_mg': calcium,
                'iron_mg': iron,
                'potassium_mg': potassium,
                'magnesium_mg': magnesium,
                'sodium_mg': sodium,
                'zinc_mg': zinc,
            }
        }
        records.append(rec)

    print(f"  -> Converted {len(records)} items from {filepath}")
    return records

def process_india():
    print("Processing India combined dataset...")
    records = []
    seen = set()

    # 1. Start with existing high-fidelity 2.6k dishes
    existing_path = os.path.join(ASSETS_DIR, 'food_nutrition_db.json')
    if os.path.exists(existing_path):
        with open(existing_path) as f:
            existing = json.load(f)
            for item in existing:
                name = item['name'].strip()
                if name and name not in seen:
                    seen.add(name)
                    records.append(item)
        print(f"  Loaded {len(records)} existing Indian dish records.")

    # 2. Add India per-serving published
    per_serv_path = os.path.join(ALL_COUNTRIES_DIR, 'India per-serving (published).xlsx')
    if os.path.exists(per_serv_path):
        wb = openpyxl.load_workbook(per_serv_path, read_only=True)
        sheet = wb.active
        rows = sheet.iter_rows(values_only=True)
        header = [str(c).strip() if c else '' for c in next(rows)]
        count = 0
        for r in rows:
            if not r or not r[0]: continue
            row_dict = dict(zip(header, r))
            name = str(row_dict.get('Item name', '')).strip()
            if not name or name in seen: continue
            seen.add(name)

            cals = safe_int(row_dict.get('Calories'))
            protein = safe_float(row_dict.get('Protein (g)'))
            carbs = safe_float(row_dict.get('Carbohydrates (g)'))
            fats = safe_float(row_dict.get('Fats (g)'))
            fiber = safe_float(row_dict.get('Fiber (g)'))
            serv_w = safe_int(row_dict.get('Serving weight (g)'), 150)
            if serv_w <= 0: serv_w = 150
            category = str(row_dict.get('Category') or 'Indian').strip()

            sodium = safe_float(row_dict.get('Sodium'))
            rec = {
                'name': name,
                'region': category.title(),
                'diet': 'Veg' if 'veg' in category.lower() else 'Standard',
                'meal_type': 'Meal',
                'serving_unit': str(row_dict.get('Typical serving') or '1 serving').strip(),
                'serving_weight_g': serv_w,
                'calories_per_100g': cals,
                'protein_g': protein,
                'carbs_g': carbs,
                'fats_g': fats,
                'fiber_g': fiber,
                'healthy_score': compute_health_score(cals, protein, fiber, sodium),
                'micronutrients_per_100g': {
                    'vitamin_a_ug': safe_float(row_dict.get('Vitamin A')),
                    'vitamin_c_mg': safe_float(row_dict.get('Vitamin C')),
                    'vitamin_b6_mg': safe_float(row_dict.get('Vitamin B6')),
                    'calcium_mg': safe_float(row_dict.get('Calcium')),
                    'iron_mg': safe_float(row_dict.get('Iron')),
                    'potassium_mg': safe_float(row_dict.get('Potassium')),
                    'magnesium_mg': safe_float(row_dict.get('Magnesium')),
                    'sodium_mg': sodium,
                    'zinc_mg': safe_float(row_dict.get('Zinc')),
                }
            }
            records.append(rec)
            count += 1
        print(f"  Added {count} recipes from India per-serving.")

    # 3. Add official India.xlsx
    india_official_path = os.path.join(ALL_COUNTRIES_DIR, 'India.xlsx')
    if os.path.exists(india_official_path):
        official = convert_standard_sheet(india_official_path, 'India', 'India')
        count = 0
        for item in official:
            name = item['name'].strip()
            if name and name not in seen:
                seen.add(name)
                records.append(item)
                count += 1
        print(f"  Added {count} items from India.xlsx.")

    return records

def main():
    countries = [
        ('usa', 'all-countries/USA.xlsx', 'United States', 'American / USA', '🇺🇸'),
        ('italy', 'all-countries/Italy.xlsx', 'Italy', 'Italian & Mediterranean', '🇮🇹'),
        ('japan', 'all-countries/Japan.xlsx', 'Japan', 'Japanese & Asian', '🇯🇵'),
        ('uk', 'all-countries/UK.xlsx', 'United Kingdom', 'British / UK', '🇬🇧'),
        ('germany', 'all-countries/Germany.xlsx', 'Germany', 'German Cuisine', '🇩🇪'),
        ('france', 'all-countries/France.xlsx', 'France', 'French Cuisine', '🇫🇷'),
        ('spain', 'all-countries/Spain.xlsx', 'Spain', 'Spanish Cuisine', '🇪🇸'),
        ('canada', 'all-countries/Canada.xlsx', 'Canada', 'Canadian Cuisine', '🇨🇦'),
        ('australia', 'all-countries/Australia.xlsx', 'Australia', 'Australian Cuisine', '🇦🇺'),
        ('netherlands', 'all-countries/Netherlands.xlsx', 'Netherlands', 'Dutch & European', '🇳🇱'),
    ]

    meta = []

    # First, India
    india_records = process_india()
    india_file = os.path.join(DATA_DIR, 'india.json')
    with open(india_file, 'w', encoding='utf-8') as f:
        json.dump(india_records, f, separators=(',', ':'))
    print(f"Saved {india_file} ({len(india_records)} records, {os.path.getsize(india_file)/(1024*1024):.2f} MB)")

    meta.append({
        'id': 'india',
        'name': 'Indian Cuisine',
        'country': 'India',
        'flag': '🇮🇳',
        'count': len(india_records),
        'description': 'IFCT ICMR-NIN, INDB, regional recipes, sweets & dishes',
        'asset': 'assets/food_data/india.json',
    })

    # Then each other country
    for cat_id, filepath, default_reg, display_name, flag in countries:
        if not os.path.exists(filepath):
            print(f"Skipping {filepath} (not found)")
            continue
        recs = convert_standard_sheet(filepath, default_reg, default_reg)
        out_file = os.path.join(DATA_DIR, f"{cat_id}.json")
        with open(out_file, 'w', encoding='utf-8') as f:
            json.dump(recs, f, separators=(',', ':'))
        print(f"Saved {out_file} ({len(recs)} records, {os.path.getsize(out_file)/(1024*1024):.2f} MB)")

        meta.append({
            'id': cat_id,
            'name': display_name,
            'country': default_reg,
            'flag': flag,
            'count': len(recs),
            'description': f"{default_reg} national composition & market database",
            'asset': f"assets/food_data/{cat_id}.json",
        })

    meta_file = os.path.join(DATA_DIR, 'categories_meta.json')
    with open(meta_file, 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2)
    print(f"Saved metadata: {meta_file}")

    total_all = sum(m['count'] for m in meta)
    print(f"=== FINISHED! TOTAL VERIFIED FOODS ACROSS ALL CATEGORIES: {total_all} ===")

if __name__ == '__main__':
    main()
