CREATE TABLE IF NOT EXISTS public.email_templates_audita_lead (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  type text NOT NULL UNIQUE, -- 'signup', 'recovery', 'invite'
  subject text NOT NULL,
  html_content text NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.email_templates_audita_lead ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super Admins can manage templates" ON public.email_templates_audita_lead;

CREATE POLICY "Super Admins can manage templates" ON public.email_templates_audita_lead
  USING (
    EXISTS (
      SELECT 1 FROM users_audita_lead 
      WHERE users_audita_lead.auth_user_id = auth.uid() 
      AND users_audita_lead.role = 'superadmin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users_audita_lead 
      WHERE users_audita_lead.auth_user_id = auth.uid() 
      AND users_audita_lead.role = 'superadmin'
    )
  );;
