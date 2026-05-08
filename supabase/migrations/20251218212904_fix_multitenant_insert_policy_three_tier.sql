-- Fix the INSERT policy to handle three-tier multitenant architecture
DROP POLICY IF EXISTS "Users can insert themselves" ON public.users_dispara_lead_saas_02;

-- Create proper INSERT policy for three-tier system
CREATE POLICY "Tenant-aware user insertion" ON public.users_dispara_lead_saas_02
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Super admins can insert users in any tenant
        is_super_admin() OR
        -- Tenant admins (owner/admin) can insert users in their own tenant
        (
            id != auth.uid() AND -- They're creating someone else (not self-registration)
            tenant_id = get_my_tenant_id() AND -- Must be in their tenant
            EXISTS (
                SELECT 1 FROM users_dispara_lead_saas_02 
                WHERE id = auth.uid() 
                AND role IN ('owner', 'admin') 
                AND tenant_id = get_my_tenant_id()
            )
        ) OR
        -- Regular users can only self-register in their assigned tenant
        (
            id = auth.uid() AND 
            tenant_id IS NOT NULL
        )
    );

-- Add comment explaining the three-tier policy
COMMENT ON POLICY "Tenant-aware user insertion" ON public.users_dispara_lead_saas_02 IS 'Three-tier multitenant policy: 1) Super admins can create users anywhere, 2) Tenant admins/owners can create users in their tenant, 3) Users can only self-register with valid tenant_id';;
