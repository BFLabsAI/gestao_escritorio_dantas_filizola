-- Remove the old "Users can view own instances" policy to avoid conflicts
DROP POLICY IF EXISTS "Users can view own instances" ON instances_dispara_lead_saas;;
