-- Adicionar campos ausentes à tabela groups_bf_tickets
ALTER TABLE groups_bf_tickets 
ADD COLUMN IF NOT EXISTS description TEXT,
ADD COLUMN IF NOT EXISTS participants_count INTEGER DEFAULT 0;;
