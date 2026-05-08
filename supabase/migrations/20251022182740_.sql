-- Ensure unique index on slug for fast lookups
CREATE UNIQUE INDEX IF NOT EXISTS idx_clients_conector_bflabs_slug 
ON public.clients_conector_bflabs(slug);

-- Index on is_active for filtering active clients
CREATE INDEX IF NOT EXISTS idx_clients_conector_bflabs_is_active 
ON public.clients_conector_bflabs(is_active) 
WHERE is_active = true;

-- Add comment to table for documentation
COMMENT ON TABLE public.clients_conector_bflabs IS 'Multi-tenant WhatsApp connector clients with workflow configurations';;
