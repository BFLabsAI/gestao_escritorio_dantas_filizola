-- Domain separation: consultations != products
-- Products are sellable items that may consume materials (inventory)
-- Consultations are scheduling templates and should not appear as products.

-- 1) consultation types scope
ALTER TABLE IF EXISTS consultation_types_evoluxhub
  ADD COLUMN IF NOT EXISTS appointment_scope TEXT NOT NULL DEFAULT 'consultation';
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'consultation_types_evoluxhub_scope_check'
  ) THEN
    ALTER TABLE consultation_types_evoluxhub
      ADD CONSTRAINT consultation_types_evoluxhub_scope_check
      CHECK (appointment_scope IN ('consultation', 'return', 'exam'));
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_consultation_types_scope
  ON consultation_types_evoluxhub(appointment_scope, is_active);
-- 2) product kind
ALTER TABLE IF EXISTS products_evoluxhub
  ADD COLUMN IF NOT EXISTS product_kind TEXT NOT NULL DEFAULT 'procedure';
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'products_evoluxhub_product_kind_check'
  ) THEN
    ALTER TABLE products_evoluxhub
      ADD CONSTRAINT products_evoluxhub_product_kind_check
      CHECK (product_kind IN ('procedure', 'package', 'retail', 'consultation_legacy'));
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_products_kind_active
  ON products_evoluxhub(product_kind, active);
-- 3) classify consultation scopes by common names
UPDATE consultation_types_evoluxhub
SET appointment_scope = 'return'
WHERE appointment_scope = 'consultation'
  AND lower(name) LIKE '%retorno%';
UPDATE consultation_types_evoluxhub
SET appointment_scope = 'exam'
WHERE appointment_scope = 'consultation'
  AND (lower(name) LIKE '%exame%' OR lower(name) LIKE '%check-up%' OR lower(name) LIKE '%checkup%');
-- 4) move procedure-like consultation templates out of consultations
WITH procedure_like AS (
  SELECT id, name, description, COALESCE(default_price, 0) AS default_price
  FROM consultation_types_evoluxhub
  WHERE is_active = true
    AND (
      lower(name) LIKE '%botox%'
      OR lower(name) LIKE '%preench%'
      OR lower(name) LIKE '%soroter%'
      OR lower(name) LIKE '%soro%'
      OR lower(name) LIKE '%toxina%'
      OR lower(name) LIKE '%procedimento%'
      OR lower(name) LIKE '%enzima%'
      OR lower(name) LIKE '%laser%'
    )
)
INSERT INTO products_evoluxhub (name, description, default_value, active, consumes_inventory, product_kind)
SELECT p.name, p.description, p.default_price, true, true, 'procedure'
FROM procedure_like p
WHERE NOT EXISTS (
  SELECT 1 FROM products_evoluxhub pr WHERE lower(pr.name) = lower(p.name)
);
UPDATE consultation_types_evoluxhub
SET is_active = false
WHERE (
  lower(name) LIKE '%botox%'
  OR lower(name) LIKE '%preench%'
  OR lower(name) LIKE '%soroter%'
  OR lower(name) LIKE '%soro%'
  OR lower(name) LIKE '%toxina%'
  OR lower(name) LIKE '%procedimento%'
  OR lower(name) LIKE '%enzima%'
  OR lower(name) LIKE '%laser%'
);
-- 5) hide consultation-like products from product flows (legacy only)
UPDATE products_evoluxhub
SET product_kind = 'consultation_legacy', active = false
WHERE lower(name) LIKE 'consulta%';
