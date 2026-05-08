create table if not exists ai_models_falconcrm (
  id text primary key,
  user_id text not null,
  name text not null,
  provider text not null,
  model_key text not null,
  is_active boolean not null default true,
  is_default boolean not null default false,
  "order" integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists ai_models_falconcrm_user_id_idx
  on ai_models_falconcrm (user_id, "order", created_at desc);

create unique index if not exists ai_models_falconcrm_user_model_key_uidx
  on ai_models_falconcrm (user_id, model_key);

create unique index if not exists ai_models_falconcrm_user_default_uidx
  on ai_models_falconcrm (user_id)
  where is_default = true;;
