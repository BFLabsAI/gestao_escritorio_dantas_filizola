-- Backfill missing evoluxhub tables detected on remote project
-- Safe to run multiple times

CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- Lookup/master tables
CREATE TABLE IF NOT EXISTS product_categories_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS payment_methods_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS insurance_providers_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS financial_categories_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'both' CHECK (type IN ('income', 'expense', 'both')),
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Inventory
CREATE TABLE IF NOT EXISTS inventory_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_name TEXT NOT NULL,
  category TEXT NOT NULL,
  quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
  unit TEXT NOT NULL DEFAULT 'unidade',
  batch_number TEXT,
  expiry_date DATE,
  min_stock_level NUMERIC(12,2) NOT NULL DEFAULT 0,
  supplier TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Nutrition planner tables (kept here too for safety in case earlier migration was not applied)
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
-- Protocol tables
CREATE TABLE IF NOT EXISTS protocol_timeline_steps_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  protocol_id UUID NOT NULL REFERENCES protocols_evoluxhub(id) ON DELETE CASCADE,
  step_name TEXT NOT NULL,
  step_order INTEGER NOT NULL DEFAULT 0,
  when_label TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS protocol_step_items_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  step_id UUID NOT NULL REFERENCES protocol_timeline_steps_evoluxhub(id) ON DELETE CASCADE,
  item_type TEXT,
  item_name TEXT NOT NULL,
  quantity NUMERIC(12,2),
  unit TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS protocol_commission_splits_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  protocol_id UUID NOT NULL REFERENCES protocols_evoluxhub(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT,
  percentage NUMERIC(5,2) NOT NULL DEFAULT 0,
  color TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT protocol_commission_splits_percentage_range CHECK (percentage >= 0 AND percentage <= 100)
);
CREATE TABLE IF NOT EXISTS protocol_enrollments_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  protocol_id UUID NOT NULL REFERENCES protocols_evoluxhub(id) ON DELETE CASCADE,
  patient_id UUID NOT NULL REFERENCES patients_evoluxhub(id) ON DELETE CASCADE,
  enrolled_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  status TEXT NOT NULL DEFAULT 'active',
  progress NUMERIC(5,2) NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT protocol_enrollments_progress_range CHECK (progress >= 0 AND progress <= 100)
);
-- Optional compatibility table that appears in mock data naming
CREATE TABLE IF NOT EXISTS doctors_evoluxhub_users_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  doctor_id UUID,
  user_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
-- Indexes
CREATE INDEX IF NOT EXISTS idx_inventory_item_name ON inventory_evoluxhub(item_name);
CREATE INDEX IF NOT EXISTS idx_inventory_category ON inventory_evoluxhub(category);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meals_plan_id ON diet_plan_meals_evoluxhub(plan_id);
CREATE INDEX IF NOT EXISTS idx_diet_plan_meal_items_meal_id ON diet_plan_meal_items_evoluxhub(meal_id);
CREATE INDEX IF NOT EXISTS idx_protocol_steps_protocol_id ON protocol_timeline_steps_evoluxhub(protocol_id);
CREATE INDEX IF NOT EXISTS idx_protocol_step_items_step_id ON protocol_step_items_evoluxhub(step_id);
CREATE INDEX IF NOT EXISTS idx_protocol_commissions_protocol_id ON protocol_commission_splits_evoluxhub(protocol_id);
CREATE INDEX IF NOT EXISTS idx_protocol_enrollments_protocol_id ON protocol_enrollments_evoluxhub(protocol_id);
CREATE INDEX IF NOT EXISTS idx_protocol_enrollments_patient_id ON protocol_enrollments_evoluxhub(patient_id);
-- Baseline seed values (idempotent)
INSERT INTO payment_methods_evoluxhub (name, description)
VALUES
  ('Pix', 'Pagamento instantâneo'),
  ('Cartão de Crédito', 'Pagamento no crédito'),
  ('Cartão de Débito', 'Pagamento no débito'),
  ('Dinheiro', 'Pagamento em dinheiro')
ON CONFLICT (name) DO NOTHING;
INSERT INTO financial_categories_evoluxhub (name, type, description)
VALUES
  ('Consulta', 'income', 'Receitas de consultas'),
  ('Procedimento', 'income', 'Receitas de procedimentos'),
  ('Suplementos', 'income', 'Receitas de suplementos/produtos'),
  ('Fornecedor', 'expense', 'Pagamentos para fornecedores'),
  ('Operacional', 'expense', 'Despesas operacionais')
ON CONFLICT (name) DO NOTHING;
INSERT INTO food_catalog_evoluxhub (name, portion_grams, calories_kcal, protein_g, carbs_g, fat_g, fiber_g, sodium_mg)
VALUES
  ('Arroz Branco', 100, 130, 2.5, 28.0, 0.3, 0.4, 1.0),
  ('Feijão Carioca', 100, 76, 4.8, 13.6, 0.5, 8.5, 2.0),
  ('Peito de Frango', 100, 165, 31.0, 0.0, 3.6, 0.0, 74.0),
  ('Ovo Cozido', 100, 155, 13.0, 1.1, 11.0, 0.0, 124.0),
  ('Banana Prata', 100, 98, 1.3, 26.0, 0.1, 2.0, 1.0)
ON CONFLICT (name) DO NOTHING;
