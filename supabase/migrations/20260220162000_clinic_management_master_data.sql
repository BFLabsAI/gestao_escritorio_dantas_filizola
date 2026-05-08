-- ============================================================================
-- CLINIC MANAGEMENT MASTER DATA HUB
-- Adds/normalizes master data tables used by Clinic Management (Cadastros)
-- Non-destructive and idempotent
-- ============================================================================

-- --------------------------------------------------------------------------
-- Core lookup tables
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS specialties_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS consultation_types_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL DEFAULT 'stethoscope',
  color TEXT NOT NULL DEFAULT 'blue',
  duration_minutes INTEGER NOT NULL DEFAULT 60,
  description TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS product_categories_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS payment_methods_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS insurance_providers_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  code TEXT,
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS financial_categories_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  type TEXT NOT NULL DEFAULT 'both' CHECK (type IN ('income', 'expense', 'both')),
  description TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE specialties_evoluxhub ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE specialties_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE specialties_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE specialties_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE specialties_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS icon TEXT NOT NULL DEFAULT 'stethoscope';
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS color TEXT NOT NULL DEFAULT 'blue';
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS duration_minutes INTEGER NOT NULL DEFAULT 60;
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS display_order INTEGER NOT NULL DEFAULT 0;
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE consultation_types_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE product_categories_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE product_categories_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE product_categories_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE product_categories_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE payment_methods_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE payment_methods_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE payment_methods_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE payment_methods_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE insurance_providers_evoluxhub ADD COLUMN IF NOT EXISTS code TEXT;
ALTER TABLE insurance_providers_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE insurance_providers_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE insurance_providers_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE insurance_providers_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE financial_categories_evoluxhub ADD COLUMN IF NOT EXISTS type TEXT NOT NULL DEFAULT 'both';
ALTER TABLE financial_categories_evoluxhub ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE financial_categories_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE financial_categories_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE financial_categories_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
-- --------------------------------------------------------------------------
-- Ensure core entities exist with required columns
-- --------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS doctors_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID,
  full_name TEXT,
  email TEXT,
  phone TEXT,
  primary_specialty_id TEXT,
  bio TEXT,
  color_code TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS rooms_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'consulta',
  capacity INTEGER,
  dedicated_specialty_id TEXT,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS full_name TEXT;
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS phone TEXT;
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE doctors_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE rooms_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE rooms_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE rooms_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
-- Backfill doctor profile fields from users table when available
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'doctors_evoluxhub' AND column_name = 'user_id'
  ) AND EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'users_evoluxhub'
  ) THEN
    EXECUTE '
      UPDATE doctors_evoluxhub d
      SET
        full_name = COALESCE(d.full_name, u.full_name),
        email = COALESCE(d.email, u.email)
      FROM users_evoluxhub u
      WHERE d.user_id = u.id
    ';
  END IF;
END $$;
-- --------------------------------------------------------------------------
-- Products normalization with backward compatibility
-- --------------------------------------------------------------------------
ALTER TABLE products_evoluxhub ADD COLUMN IF NOT EXISTS category_id UUID;
ALTER TABLE products_evoluxhub ADD COLUMN IF NOT EXISTS active BOOLEAN NOT NULL DEFAULT true;
ALTER TABLE products_evoluxhub ADD COLUMN IF NOT EXISTS default_value NUMERIC(10,2);
ALTER TABLE products_evoluxhub ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE products_evoluxhub ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products_evoluxhub' AND column_name = 'is_active'
  ) THEN
    EXECUTE 'UPDATE products_evoluxhub SET active = COALESCE(active, is_active)';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products_evoluxhub' AND column_name = 'price'
  ) THEN
    EXECUTE 'UPDATE products_evoluxhub SET default_value = COALESCE(default_value, price)';
  END IF;
END $$;
-- Migrate legacy text categories into managed categories table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'products_evoluxhub' AND column_name = 'category'
  ) THEN
    EXECUTE '
      INSERT INTO product_categories_evoluxhub (name, created_at, updated_at)
      SELECT DISTINCT TRIM(category), NOW(), NOW()
      FROM products_evoluxhub
      WHERE category IS NOT NULL AND TRIM(category) <> ''''
      ON CONFLICT (name) DO NOTHING
    ';

    EXECUTE '
      UPDATE products_evoluxhub p
      SET category_id = c.id
      FROM product_categories_evoluxhub c
      WHERE p.category_id IS NULL AND p.category IS NOT NULL AND TRIM(p.category) = c.name
    ';
  END IF;
END $$;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'products_evoluxhub_category_id_fkey'
  ) THEN
    ALTER TABLE products_evoluxhub
      ADD CONSTRAINT products_evoluxhub_category_id_fkey
      FOREIGN KEY (category_id) REFERENCES product_categories_evoluxhub(id) ON DELETE SET NULL;
  END IF;
END $$;
COMMENT ON COLUMN products_evoluxhub.category IS 'LEGACY column (deprecated). Use category_id + product_categories_evoluxhub';
-- --------------------------------------------------------------------------
-- Indexes
-- --------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_specialties_name ON specialties_evoluxhub(name);
CREATE INDEX IF NOT EXISTS idx_specialties_active ON specialties_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_consultation_types_active ON consultation_types_evoluxhub(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_product_categories_active ON product_categories_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_products_category_id ON products_evoluxhub(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active_v2 ON products_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_doctors_active ON doctors_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_doctors_primary_specialty ON doctors_evoluxhub(primary_specialty_id);
CREATE INDEX IF NOT EXISTS idx_rooms_active ON rooms_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_rooms_dedicated_specialty ON rooms_evoluxhub(dedicated_specialty_id);
CREATE INDEX IF NOT EXISTS idx_payment_methods_active ON payment_methods_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_insurance_providers_active ON insurance_providers_evoluxhub(active) WHERE active = true;
CREATE INDEX IF NOT EXISTS idx_financial_categories_active ON financial_categories_evoluxhub(active) WHERE active = true;
-- --------------------------------------------------------------------------
-- Updated at trigger helper
-- --------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION evoluxhub_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_specialties_updated_at') THEN
    CREATE TRIGGER trg_specialties_updated_at BEFORE UPDATE ON specialties_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_consultation_types_updated_at') THEN
    CREATE TRIGGER trg_consultation_types_updated_at BEFORE UPDATE ON consultation_types_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_product_categories_updated_at') THEN
    CREATE TRIGGER trg_product_categories_updated_at BEFORE UPDATE ON product_categories_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_products_updated_at_v2') THEN
    CREATE TRIGGER trg_products_updated_at_v2 BEFORE UPDATE ON products_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_doctors_updated_at_v2') THEN
    CREATE TRIGGER trg_doctors_updated_at_v2 BEFORE UPDATE ON doctors_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_rooms_updated_at_v2') THEN
    CREATE TRIGGER trg_rooms_updated_at_v2 BEFORE UPDATE ON rooms_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_payment_methods_updated_at') THEN
    CREATE TRIGGER trg_payment_methods_updated_at BEFORE UPDATE ON payment_methods_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_insurance_providers_updated_at') THEN
    CREATE TRIGGER trg_insurance_providers_updated_at BEFORE UPDATE ON insurance_providers_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_financial_categories_updated_at') THEN
    CREATE TRIGGER trg_financial_categories_updated_at BEFORE UPDATE ON financial_categories_evoluxhub FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
END $$;
-- --------------------------------------------------------------------------
-- RLS policies
-- --------------------------------------------------------------------------
ALTER TABLE specialties_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultation_types_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_categories_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE insurance_providers_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE financial_categories_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE doctors_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms_evoluxhub ENABLE ROW LEVEL SECURITY;
ALTER TABLE products_evoluxhub ENABLE ROW LEVEL SECURITY;
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT unnest(ARRAY[
      'specialties_evoluxhub',
      'consultation_types_evoluxhub',
      'product_categories_evoluxhub',
      'payment_methods_evoluxhub',
      'insurance_providers_evoluxhub',
      'financial_categories_evoluxhub',
      'doctors_evoluxhub',
      'rooms_evoluxhub',
      'products_evoluxhub'
    ])
  LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t AND policyname = t || '_read_all') THEN
      EXECUTE format('CREATE POLICY %I ON %I FOR SELECT USING (true)', t || '_read_all', t);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t AND policyname = t || '_insert_auth') THEN
      EXECUTE format('CREATE POLICY %I ON %I FOR INSERT WITH CHECK (true)', t || '_insert_auth', t);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t AND policyname = t || '_update_auth') THEN
      EXECUTE format('CREATE POLICY %I ON %I FOR UPDATE USING (true)', t || '_update_auth', t);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = t AND policyname = t || '_delete_auth') THEN
      EXECUTE format('CREATE POLICY %I ON %I FOR DELETE USING (true)', t || '_delete_auth', t);
    END IF;
  END LOOP;
END $$;
-- --------------------------------------------------------------------------
-- Seed defaults for dropdowns
-- --------------------------------------------------------------------------
INSERT INTO specialties_evoluxhub (code, name, active)
SELECT x.code, x.name, x.active
FROM (
  VALUES
    ('DERMATO', 'Dermatologia', true),
    ('NUTRO', 'Nutrologia', true),
    ('CARDIO', 'Cardiologia', true),
    ('ENDOCRINO', 'Endocrinologia', true),
    ('ORTO', 'Ortopedia', true),
    ('GINECO', 'Ginecologia', true)
) AS x(code, name, active)
WHERE NOT EXISTS (
  SELECT 1 FROM specialties_evoluxhub s WHERE s.name = x.name
);
INSERT INTO consultation_types_evoluxhub (name, icon, color, duration_minutes, description, display_order, is_active)
SELECT x.name, x.icon, x.color, x.duration_minutes, x.description, x.display_order, x.is_active
FROM (
  VALUES
    ('Consulta', 'stethoscope', 'blue', 60, 'Consulta médica padrão', 1, true),
    ('Retorno', 'assignment_return', 'green', 30, 'Consulta de retorno', 2, true),
    ('Avaliação', 'monitor_heart', 'purple', 60, 'Avaliação inicial', 3, true),
    ('Check-up', 'health_metrics', 'amber', 90, 'Check-up preventivo', 4, true),
    ('Procedimento', 'surgical', 'red', 120, 'Procedimento ambulatorial', 5, true)
) AS x(name, icon, color, duration_minutes, description, display_order, is_active)
WHERE NOT EXISTS (
  SELECT 1 FROM consultation_types_evoluxhub ct WHERE ct.name = x.name
);
INSERT INTO payment_methods_evoluxhub (name, description, active)
SELECT x.name, x.description, x.active
FROM (
  VALUES
    ('Dinheiro', 'Pagamento em espécie', true),
    ('Pix', 'Transferência instantânea', true),
    ('Cartão de Débito', 'Débito em conta', true),
    ('Cartão de Crédito', 'Parcelado ou à vista', true),
    ('Boleto', 'Cobrança bancária', true)
) AS x(name, description, active)
WHERE NOT EXISTS (
  SELECT 1 FROM payment_methods_evoluxhub pm WHERE pm.name = x.name
);
INSERT INTO insurance_providers_evoluxhub (name, code, active)
SELECT x.name, x.code, x.active
FROM (
  VALUES
    ('Particular', 'PART', true),
    ('Unimed', 'UNIMED', true),
    ('SulAmérica', 'SULAMERICA', true),
    ('Bradesco Saúde', 'BRADESCO', true)
) AS x(name, code, active)
WHERE NOT EXISTS (
  SELECT 1 FROM insurance_providers_evoluxhub ip WHERE ip.name = x.name
);
INSERT INTO financial_categories_evoluxhub (name, type, active)
SELECT x.name, x.type, x.active
FROM (
  VALUES
    ('Consulta', 'income', true),
    ('Procedimento', 'income', true),
    ('Exame', 'income', true),
    ('Folha de Pagamento', 'expense', true),
    ('Aluguel', 'expense', true),
    ('Insumos', 'expense', true)
) AS x(name, type, active)
WHERE NOT EXISTS (
  SELECT 1 FROM financial_categories_evoluxhub fc WHERE fc.name = x.name
);
