-- Create leads_dispara_lead table for landing page lead capture
create table if not exists public.leads_dispara_lead (
  id uuid default gen_random_uuid() primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  
  -- Form Data
  nome text not null,
  email text not null,
  whatsapp text not null,
  nome_empresa text,
  ja_faz_disparo boolean default false,
  
  -- UTM Tracking
  utm_source text,
  utm_medium text,
  utm_campaign text,
  utm_term text,
  utm_content text,
  
  -- Device Tracking
  device_type text check (device_type in ('web', 'android', 'iphone')),
  user_agent text,
  
  -- Metadata
  referrer text,
  landing_page_url text
);

-- Enable RLS
alter table public.leads_dispara_lead enable row level security;

-- Policy: Anyone can insert (public form)
create policy "Anyone can insert leads"
  on public.leads_dispara_lead
  for insert
  with check (true);

-- Policy: Only authenticated users can view
create policy "Authenticated users can view leads"
  on public.leads_dispara_lead
  for select
  using (auth.role() = 'authenticated');;
