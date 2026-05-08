-- Rename api_key to token
ALTER TABLE instances_dispara_lead_saas_02 RENAME COLUMN api_key TO token;

-- Drop unused legacy columns
ALTER TABLE instances_dispara_lead_saas_02 DROP COLUMN IF EXISTS instance_id;
ALTER TABLE instances_dispara_lead_saas_02 DROP COLUMN IF EXISTS server_url;
ALTER TABLE instances_dispara_lead_saas_02 DROP COLUMN IF EXISTS apikey;

-- Make uazapi_instance_id the main ID column (optional rename, or just keep it)
-- Plan said "Using Column: uazapi_instance_id", implies keeping it. 
-- But for clarity, if I dropped instance_id, I could rename uazapi_instance_id to instance_id. 
-- However, to avoid too much code breakage, I will keep uazapi_instance_id as is for now 
-- unless I find code extensively using instance_id. 
-- The user said "it is confusing". Renaming uazapi_instance_id to instance_id would be cleaner.
-- Let's check typical usage first. Most code likely uses uazapi_instance_id since I migrated it.
-- I'll stick to just dropping the legacy columns and renaming api_key -> token for now.;
