-- Reconciliation migration: consultation pricing + product BOM + inventory movements
-- Idempotent by design.

CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- 1) Consultation types default price
ALTER TABLE IF EXISTS consultation_types_evoluxhub
  ADD COLUMN IF NOT EXISTS default_price NUMERIC(10,2) NOT NULL DEFAULT 0;
-- 2) Appointments: consultation linkage, price snapshot and realization markers
ALTER TABLE IF EXISTS appointments_evoluxhub
  ADD COLUMN IF NOT EXISTS consultation_type_id UUID NULL,
  ADD COLUMN IF NOT EXISTS quoted_price NUMERIC(10,2) NULL,
  ADD COLUMN IF NOT EXISTS realized_at TIMESTAMPTZ NULL,
  ADD COLUMN IF NOT EXISTS stock_deducted_at TIMESTAMPTZ NULL;
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'appointments_evoluxhub_consultation_type_id_fkey'
  ) THEN
    ALTER TABLE appointments_evoluxhub
      ADD CONSTRAINT appointments_evoluxhub_consultation_type_id_fkey
      FOREIGN KEY (consultation_type_id)
      REFERENCES consultation_types_evoluxhub(id)
      ON DELETE SET NULL;
  END IF;
END $$;
CREATE INDEX IF NOT EXISTS idx_appointments_consultation_type_id
  ON appointments_evoluxhub(consultation_type_id);
CREATE INDEX IF NOT EXISTS idx_appointments_realized_at
  ON appointments_evoluxhub(realized_at);
-- 3) Products: inventory consumption flag
ALTER TABLE IF EXISTS products_evoluxhub
  ADD COLUMN IF NOT EXISTS consumes_inventory BOOLEAN NOT NULL DEFAULT true;
-- 4) Inventory canonical balance on inventory_items
ALTER TABLE IF EXISTS inventory_items_evoluxhub
  ADD COLUMN IF NOT EXISTS current_stock NUMERIC(12,3) NOT NULL DEFAULT 0;
-- 5) Product BOM table
CREATE TABLE IF NOT EXISTS product_materials_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products_evoluxhub(id) ON DELETE CASCADE,
  inventory_item_id UUID NOT NULL REFERENCES inventory_items_evoluxhub(id) ON DELETE RESTRICT,
  default_quantity NUMERIC(12,3) NOT NULL CHECK (default_quantity > 0),
  unit TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (product_id, inventory_item_id, unit)
);
CREATE INDEX IF NOT EXISTS idx_product_materials_product_id
  ON product_materials_evoluxhub(product_id);
CREATE INDEX IF NOT EXISTS idx_product_materials_inventory_item_id
  ON product_materials_evoluxhub(inventory_item_id);
-- 6) Inventory movement ledger
CREATE TABLE IF NOT EXISTS inventory_movements_evoluxhub (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  inventory_item_id UUID NOT NULL REFERENCES inventory_items_evoluxhub(id) ON DELETE RESTRICT,
  movement_type TEXT NOT NULL CHECK (movement_type IN ('in','out','adjustment','reversal')),
  quantity NUMERIC(12,3) NOT NULL CHECK (quantity > 0),
  unit TEXT NOT NULL,
  reason TEXT,
  reference_type TEXT,
  reference_id UUID,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_item_id
  ON inventory_movements_evoluxhub(inventory_item_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_inventory_movements_reference
  ON inventory_movements_evoluxhub(reference_type, reference_id);
-- updated_at trigger helper (re-use if already exists)
CREATE OR REPLACE FUNCTION evoluxhub_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'trg_product_materials_updated_at') THEN
    CREATE TRIGGER trg_product_materials_updated_at
      BEFORE UPDATE ON product_materials_evoluxhub
      FOR EACH ROW EXECUTE FUNCTION evoluxhub_set_updated_at();
  END IF;
END $$;
-- 7) Transactional RPC: finalize appointment stock deduction
CREATE OR REPLACE FUNCTION rpc_finalize_appointment_inventory(
  p_appointment_id UUID,
  p_overrides JSONB DEFAULT '[]'::jsonb
)
RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_appt RECORD;
  v_consumes_inventory BOOLEAN;
  v_missing JSONB;
  v_total_items INTEGER := 0;
BEGIN
  SELECT id, type, procedure_id, stock_deducted_at
  INTO v_appt
  FROM appointments_evoluxhub
  WHERE id = p_appointment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Appointment % not found', p_appointment_id USING ERRCODE = 'P0002';
  END IF;

  IF v_appt.stock_deducted_at IS NOT NULL THEN
    RAISE EXCEPTION 'Stock already deducted for appointment %', p_appointment_id USING ERRCODE = 'P0001';
  END IF;

  IF COALESCE(v_appt.type, '') <> 'procedure' THEN
    RETURN jsonb_build_object('status', 'skipped', 'reason', 'non_procedure');
  END IF;

  IF v_appt.procedure_id IS NULL THEN
    RAISE EXCEPTION 'Procedure appointment % has no procedure_id', p_appointment_id USING ERRCODE = 'P0001';
  END IF;

  SELECT COALESCE(consumes_inventory, true)
  INTO v_consumes_inventory
  FROM products_evoluxhub
  WHERE id = v_appt.procedure_id;

  IF COALESCE(v_consumes_inventory, true) = false THEN
    UPDATE appointments_evoluxhub
    SET stock_deducted_at = now()
    WHERE id = p_appointment_id;

    RETURN jsonb_build_object('status', 'skipped', 'reason', 'product_does_not_consume_inventory');
  END IF;

  CREATE TEMP TABLE tmp_requirements (
    inventory_item_id UUID PRIMARY KEY,
    quantity NUMERIC(12,3) NOT NULL,
    unit TEXT NOT NULL
  ) ON COMMIT DROP;

  INSERT INTO tmp_requirements (inventory_item_id, quantity, unit)
  SELECT inventory_item_id, default_quantity, unit
  FROM product_materials_evoluxhub
  WHERE product_id = v_appt.procedure_id;

  IF jsonb_typeof(COALESCE(p_overrides, '[]'::jsonb)) = 'array' AND jsonb_array_length(COALESCE(p_overrides, '[]'::jsonb)) > 0 THEN
    WITH overrides AS (
      SELECT
        (o->>'inventory_item_id')::uuid AS inventory_item_id,
        NULLIF(o->>'quantity', '')::numeric AS quantity,
        NULLIF(o->>'unit', '') AS unit
      FROM jsonb_array_elements(p_overrides) o
      WHERE o ? 'inventory_item_id'
    )
    INSERT INTO tmp_requirements (inventory_item_id, quantity, unit)
    SELECT inventory_item_id, GREATEST(COALESCE(quantity, 0), 0), COALESCE(unit, '')
    FROM overrides
    ON CONFLICT (inventory_item_id)
    DO UPDATE SET
      quantity = COALESCE(EXCLUDED.quantity, tmp_requirements.quantity),
      unit = CASE WHEN EXCLUDED.unit <> '' THEN EXCLUDED.unit ELSE tmp_requirements.unit END;

    DELETE FROM tmp_requirements WHERE quantity <= 0;
  END IF;

  SELECT COUNT(*) INTO v_total_items FROM tmp_requirements;

  IF v_total_items = 0 THEN
    UPDATE appointments_evoluxhub
    SET stock_deducted_at = now()
    WHERE id = p_appointment_id;

    RETURN jsonb_build_object('status', 'skipped', 'reason', 'no_materials');
  END IF;

  SELECT jsonb_agg(
           jsonb_build_object(
             'inventory_item_id', req.inventory_item_id,
             'required', req.quantity,
             'available', COALESCE(item.current_stock, 0),
             'unit', req.unit
           )
         )
  INTO v_missing
  FROM tmp_requirements req
  LEFT JOIN inventory_items_evoluxhub item ON item.id = req.inventory_item_id
  WHERE COALESCE(item.current_stock, 0) < req.quantity;

  IF v_missing IS NOT NULL THEN
    RAISE EXCEPTION 'Insufficient stock for appointment %', p_appointment_id
      USING ERRCODE = 'P0001', DETAIL = v_missing::text;
  END IF;

  UPDATE inventory_items_evoluxhub item
  SET current_stock = item.current_stock - req.quantity
  FROM tmp_requirements req
  WHERE item.id = req.inventory_item_id;

  INSERT INTO inventory_movements_evoluxhub (
    inventory_item_id,
    movement_type,
    quantity,
    unit,
    reason,
    reference_type,
    reference_id,
    metadata
  )
  SELECT
    req.inventory_item_id,
    'out',
    req.quantity,
    req.unit,
    'appointment_procedure_consumption',
    'appointment',
    p_appointment_id,
    jsonb_build_object(
      'appointment_id', p_appointment_id,
      'procedure_id', v_appt.procedure_id,
      'source', 'rpc_finalize_appointment_inventory'
    )
  FROM tmp_requirements req;

  UPDATE appointments_evoluxhub
  SET stock_deducted_at = now()
  WHERE id = p_appointment_id;

  RETURN jsonb_build_object(
    'status', 'ok',
    'deducted_items', v_total_items,
    'appointment_id', p_appointment_id
  );
END;
$$;
