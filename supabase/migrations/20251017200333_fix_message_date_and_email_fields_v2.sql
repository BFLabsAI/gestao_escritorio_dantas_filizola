-- Fix missing fields and ensure proper schema alignment
-- Migration to add missing fields based on actual usage in edge functions and frontend

-- First, let's add the missing fields without trying to update from non-existent fields
ALTER TABLE mensagens_rastreia_prospect
ADD COLUMN IF NOT EXISTS message_date TIMESTAMP WITH TIME ZONE NULL DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS status TEXT NULL DEFAULT 'received';

-- Add missing email field to vendedores_rastreia_prospect table
ALTER TABLE vendedores_rastreia_prospect
ADD COLUMN IF NOT EXISTS email TEXT NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_mensagens_message_date ON mensagens_rastreia_prospect(message_date DESC);
CREATE INDEX IF NOT EXISTS idx_mensagens_status ON mensagens_rastreia_prospect(status);
CREATE INDEX IF NOT EXISTS idx_vendedores_email ON vendedores_rastreia_prospect(email);

-- Add comments to document the fields
COMMENT ON COLUMN mensagens_rastreia_prospect.message_date IS 'Date when the message was sent/received';
COMMENT ON COLUMN mensagens_rastreia_prospect.status IS 'Current status of the message (received, sent, processed, etc.)';
COMMENT ON COLUMN vendedores_rastreia_prospect.email IS 'Email address of the vendor/seller';;
