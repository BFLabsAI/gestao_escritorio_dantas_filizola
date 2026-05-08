
-- Recreate helper functions to properly bypass RLS
-- Using plpgsql with explicit row_security = off

CREATE OR REPLACE FUNCTION public.get_user_tenant_id_audita_lead()
RETURNS uuid
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_tenant_id uuid;
BEGIN
  SELECT tenant_id INTO v_tenant_id
  FROM users_audita_lead 
  WHERE auth_user_id = auth.uid();
  
  RETURN v_tenant_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_superadmin_audita_lead()
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
SET row_security = off
AS $$
DECLARE
  v_is_superadmin boolean;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM users_audita_lead 
    WHERE auth_user_id = auth.uid() AND role = 'superadmin'
  ) INTO v_is_superadmin;
  
  RETURN COALESCE(v_is_superadmin, false);
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_user_tenant_id_audita_lead() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_superadmin_audita_lead() TO authenticated;
;
