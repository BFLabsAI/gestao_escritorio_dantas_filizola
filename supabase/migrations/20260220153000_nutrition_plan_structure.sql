-- Nutrition planner persistence structure
-- Backward compatible extension over dist_plans_evoluxhub + anthropometry_evoluxhub

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS food_catalog_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  portion_grams NUMERIC(10,2) NOT NULL DEFAULT 100,
  calories_kcal NUMERIC(10,2) NOT NULL DEFAULT 0,
  protein_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  carbs_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  fat_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  fiber_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  sodium_mg NUMERIC(10,2) NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS diet_plan_meals_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id UUID NOT NULL REFERENCES dist_plans_evoluxhub(id) ON DELETE CASCADE,
  meal_name TEXT NOT NULL,
  meal_order INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS diet_plan_meal_items_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_id UUID NOT NULL REFERENCES diet_plan_meals_evoluxhub(id) ON DELETE CASCADE,
  food_id UUID NULL REFERENCES food_catalog_evoluxhub(id) ON DELETE SET NULL,
  food_name TEXT NOT NULL,
  quantity_grams NUMERIC(10,2) NOT NULL DEFAULT 0,
  calories_kcal NUMERIC(10,2) NOT NULL DEFAULT 0,
  protein_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  carbs_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  fat_g NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meals_plan_id
  ON diet_plan_meals_evoluxhub(plan_id);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meals_order
  ON diet_plan_meals_evoluxhub(plan_id, meal_order);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meal_items_meal_id
  ON diet_plan_meal_items_evoluxhub(meal_id);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meal_items_food_id
  ON diet_plan_meal_items_evoluxhub(food_id);
INSERT INTO food_catalog_evoluxhub (name, portion_grams, calories_kcal, protein_g, carbs_g, fat_g, fiber_g, sodium_mg)
VALUES
  ('Arroz Branco', 100, 130, 2.5, 28.0, 0.3, 0.4, 1.0),
  ('Feijão Carioca', 100, 76, 4.8, 13.6, 0.5, 8.5, 2.0),
  ('Peito de Frango', 100, 165, 31.0, 0.0, 3.6, 0.0, 74.0),
  ('Ovo Cozido', 100, 155, 13.0, 1.1, 11.0, 0.0, 124.0),
  ('Banana Prata', 100, 98, 1.3, 26.0, 0.1, 2.0, 1.0)
ON CONFLICT (name) DO NOTHING;
