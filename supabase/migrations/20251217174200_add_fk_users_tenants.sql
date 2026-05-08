ALTER TABLE users_dispara_lead_saas_02 
ADD CONSTRAINT fk_users_tenants 
FOREIGN KEY (tenant_id) 
REFERENCES tenants_dispara_lead_saas_02 (id) 
ON DELETE SET NULL;;
