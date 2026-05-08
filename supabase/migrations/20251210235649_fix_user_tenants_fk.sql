
-- Ensure auth_user_id is unique
ALTER TABLE users_audita_lead
ADD CONSTRAINT users_audita_lead_auth_user_id_key UNIQUE (auth_user_id);

-- Drop old FK to auth.users
ALTER TABLE user_tenants_audita_lead
DROP CONSTRAINT IF EXISTS user_tenants_audita_lead_user_id_fkey;

-- Add new FK to users_audita_lead(auth_user_id)
ALTER TABLE user_tenants_audita_lead
ADD CONSTRAINT user_tenants_audita_lead_user_id_fkey
FOREIGN KEY (user_id)
REFERENCES users_audita_lead(auth_user_id)
ON DELETE CASCADE;
;
