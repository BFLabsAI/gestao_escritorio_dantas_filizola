DO $$
DECLARE
  v_tenant_id UUID;
  v_plan_id UUID;
BEGIN
  -- 1. Get or Create Plan
  SELECT id INTO v_plan_id FROM plans_dispara_lead_saas WHERE slug = 'enterprise';
  IF v_plan_id IS NULL THEN
     INSERT INTO plans_dispara_lead_saas (name, slug, max_instances, max_messages_month) VALUES ('Enterprise', 'enterprise', 50, 1000000) RETURNING id INTO v_plan_id;
  END IF;

  -- 2. Create Tenant 'R7 Treinamentos'
  INSERT INTO tenants_dispara_lead_saas (name, slug, plan_id, status)
  VALUES ('R7 Treinamentos', 'r7-treinamentos', v_plan_id, 'active')
  ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name
  RETURNING id INTO v_tenant_id;

  -- 3. Migrate Message Logs
  INSERT INTO message_logs_dispara_lead_saas (
    tenant_id, instance_name, phone_number, message_content, 
    status, campaign_name, campaign_type, metadata, created_at
  )
  SELECT 
    v_tenant_id, instancia, numero, texto, 
    CASE WHEN tipo_envio = 'sucesso' THEN 'sent' ELSE 'failed' END,
    nome_campanha, tipo_campanha, 
    jsonb_build_object('publico', publico, 'criativo', criativo, 'usaria', usaria),
    created_at
  FROM disparador_r7_treinamentos;

  -- 4. Migrate Schedules
  INSERT INTO schedules_dispara_lead_saas (
    tenant_id, campaign_name, scheduled_at, status, 
    contacts_json, message_template, instance_names, 
    execution_log, created_at
  )
  SELECT 
    v_tenant_id, campaign_name, scheduled_at, status,
    contacts_json, message_templates, 
    (SELECT array_agg(x) FROM jsonb_array_elements_text(selected_instances) t(x)),
    execution_log, created_at
  FROM agendamentos_disparador_r7_treinamentos;

  -- 5. Migrate Chat Sessions (Group by chat_id)
  INSERT INTO chat_sessions_dispara_lead_saas (
    id, tenant_id, session_name, template_used, created_at
  )
  SELECT DISTINCT ON (chat_id)
    chat_id, v_tenant_id, session_name, template_used, created_at
  FROM copy_agent_disparador_r7_treinamentos
  ORDER BY chat_id, created_at ASC
  ON CONFLICT (id) DO NOTHING;

  -- 6. Migrate Chat Messages
  INSERT INTO chat_messages_dispara_lead_saas (
    session_id, role, content, metadata, created_at
  )
  SELECT 
    chat_id, message_role, message_content, metadata, created_at
  FROM copy_agent_disparador_r7_treinamentos;

  -- 7. Auto-register Instances from History (containing 'R7' or 'r7')
  INSERT INTO instances_dispara_lead_saas (tenant_id, instance_name, status, connection_status)
  SELECT DISTINCT v_tenant_id, instancia, 'connected', 'open'
  FROM disparador_r7_treinamentos
  WHERE instancia ILIKE '%r7%'
  ON CONFLICT (tenant_id, instance_name) DO NOTHING;

END $$;;
