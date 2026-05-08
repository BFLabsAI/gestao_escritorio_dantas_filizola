create table if not exists custom_prompt_disparador_r7_treinamentos (
  id uuid default gen_random_uuid() primary key,
  user_id text not null,
  company_name text,
  market_segment text,
  company_size text,
  brand_voice text,
  brand_personality text,
  preferred_language text,
  main_products text,
  average_ticket text,
  sales_cycle text,
  seasonality text,
  main_persona text,
  age_range text,
  social_class text,
  primary_goal text,
  secondary_goals text[],
  main_competitors text,
  whatsapp_preferences jsonb,
  updated_at timestamptz default now(),
  unique(user_id)
);

-- Add RLS policies if needed, but for now just ensuring table exists
alter table custom_prompt_disparador_r7_treinamentos enable row level security;

create policy "Users can view their own settings"
  on custom_prompt_disparador_r7_treinamentos for select
  using (true); -- ideally auth.uid()::text = user_id but we are using 'default-user' hardcoded for now

create policy "Users can insert/update their own settings"
  on custom_prompt_disparador_r7_treinamentos for all
  using (true);;
