-- Add missing INSERT policy for users_dispara_lead_saas_02
-- This allows user registration through the application

-- Policy for allowing user registration (INSERT)
-- Only authenticated users can insert new users, and only if they are super admins or creating themselves
CREATE POLICY "Users can insert themselves" ON public.users_dispara_lead_saas_02
    FOR INSERT
    TO authenticated
    WITH CHECK (
        -- Allow super admins to insert any user
        is_super_admin() OR
        -- Allow users to insert their own record (for registration)
        id = auth.uid()
    );

-- Policy for allowing user deletion (DELETE)
-- Only super admins can delete users, and users can delete themselves
CREATE POLICY "Super admins can delete users" ON public.users_dispara_lead_saas_02
    FOR DELETE
    TO authenticated
    USING (
        is_super_admin() OR
        -- Allow users to delete their own account
        id = auth.uid()
    );

-- Add a comment to document what was fixed
COMMENT ON POLICY "Users can insert themselves" ON public.users_dispara_lead_saas_02 IS 'Allows user registration and super admin user creation';
COMMENT ON POLICY "Super admins can delete users" ON public.users_dispara_lead_saas_02 IS 'Allows super admins and self-deletion of user accounts';;
