-- Create consultants table
CREATE TABLE IF NOT EXISTS public.consultants_audita_lead (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tenant_id UUID NOT NULL REFERENCES public.tenants_audita_lead(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    user_id UUID REFERENCES public.users_audita_lead(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.consultants_audita_lead ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies (Same as other tables)
CREATE POLICY "Enable read access for users in same tenant" ON public.consultants_audita_lead
    FOR SELECT USING (
        auth.uid() IN (
            SELECT auth_user_id FROM public.users_audita_lead WHERE tenant_id = consultants_audita_lead.tenant_id
        )
    );

CREATE POLICY "Enable insert access for users in same tenant" ON public.consultants_audita_lead
    FOR INSERT WITH CHECK (
        auth.uid() IN (
            SELECT auth_user_id FROM public.users_audita_lead WHERE tenant_id = consultants_audita_lead.tenant_id
        )
    );

CREATE POLICY "Enable update access for users in same tenant" ON public.consultants_audita_lead
    FOR UPDATE USING (
        auth.uid() IN (
            SELECT auth_user_id FROM public.users_audita_lead WHERE tenant_id = consultants_audita_lead.tenant_id
        )
    );

CREATE POLICY "Enable delete access for users in same tenant" ON public.consultants_audita_lead
    FOR DELETE USING (
        auth.uid() IN (
            SELECT auth_user_id FROM public.users_audita_lead WHERE tenant_id = consultants_audita_lead.tenant_id
        )
    );

-- Add consultant_id to instances
ALTER TABLE public.instances_audita_lead 
ADD COLUMN IF NOT EXISTS consultant_id UUID REFERENCES public.consultants_audita_lead(id) ON DELETE SET NULL;
;
