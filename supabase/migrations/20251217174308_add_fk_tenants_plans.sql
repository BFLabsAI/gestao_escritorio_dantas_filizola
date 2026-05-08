ALTER TABLE tenants_dispara_lead_saas_02 
ADD CONSTRAINT fk_tenants_plans
FOREIGN KEY (plan_id) 
REFERENCES plans_dispara_lead_saas_02 (id) 
ON DELETE SET NULL;;
