
-- Remover constraint antiga
ALTER TABLE relatorio_google_fact_search_term_performance 
DROP CONSTRAINT IF EXISTS unique_fact_campaign_daily;

-- Criar nova constraint que inclui todos os níveis
-- A constraint única deve considerar: date, cliente_id, campaign_id, ad_group_id, keyword_id, search_term_id
ALTER TABLE relatorio_google_fact_search_term_performance 
ADD CONSTRAINT unique_fact_daily 
UNIQUE (date, cliente_id, campaign_id, ad_group_id, keyword_id, search_term_id);
;
