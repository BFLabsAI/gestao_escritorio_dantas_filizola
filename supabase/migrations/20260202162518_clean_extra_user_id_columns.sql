-- Remover colunas user_id extras (vamos manter person_id nas tabelas relacionadas)
ALTER TABLE events_itarget_api DROP COLUMN IF EXISTS user_id;
ALTER TABLE subscriptions_itarget_api DROP COLUMN IF EXISTS user_id;;
