ALTER TABLE instances_clientes_bf_labs
ADD COLUMN IF NOT EXISTS webhook_only BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN instances_clientes_bf_labs.webhook_only IS 'When true, instance was imported (no QR code needed)';;
