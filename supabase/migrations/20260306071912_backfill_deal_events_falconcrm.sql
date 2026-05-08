insert into public.deal_events_falconcrm (
  id,
  deal_id,
  user_id,
  event_type,
  to_stage_id,
  to_stage_name,
  loss_reason_id,
  amount_snapshot,
  probability_snapshot,
  metadata,
  created_at
)
select
  gen_random_uuid(),
  d.id,
  d.user_id,
  'deal_created',
  d.stage_id,
  s.name,
  d.loss_reason_id,
  d.estimated_value,
  d.probability,
  jsonb_build_object(
    'backfilled', true,
    'dealName', d.name,
    'company', d.company
  ),
  d.created_at
from public.deals_falconcrm d
left join public.stages_falconcrm s on s.id = d.stage_id
where not exists (
  select 1
  from public.deal_events_falconcrm e
  where e.deal_id = d.id
    and e.event_type = 'deal_created'
);

insert into public.deal_events_falconcrm (
  id,
  deal_id,
  user_id,
  event_type,
  to_stage_id,
  to_stage_name,
  loss_reason_id,
  amount_snapshot,
  probability_snapshot,
  metadata,
  created_at
)
select
  gen_random_uuid(),
  d.id,
  d.user_id,
  'deal_won',
  d.stage_id,
  s.name,
  d.loss_reason_id,
  d.estimated_value,
  d.probability,
  jsonb_build_object('backfilled', true),
  coalesce(d.closed_at, d.updated_at, d.created_at)
from public.deals_falconcrm d
join public.stages_falconcrm s
  on s.id = d.stage_id
 and s.is_won = true
where not exists (
  select 1
  from public.deal_events_falconcrm e
  where e.deal_id = d.id
    and e.event_type = 'deal_won'
);

insert into public.deal_events_falconcrm (
  id,
  deal_id,
  user_id,
  event_type,
  to_stage_id,
  to_stage_name,
  loss_reason_id,
  amount_snapshot,
  probability_snapshot,
  metadata,
  created_at
)
select
  gen_random_uuid(),
  d.id,
  d.user_id,
  'deal_lost',
  d.stage_id,
  s.name,
  d.loss_reason_id,
  d.estimated_value,
  d.probability,
  jsonb_build_object('backfilled', true),
  coalesce(d.closed_at, d.updated_at, d.created_at)
from public.deals_falconcrm d
join public.stages_falconcrm s
  on s.id = d.stage_id
 and s.is_lost = true
where not exists (
  select 1
  from public.deal_events_falconcrm e
  where e.deal_id = d.id
    and e.event_type = 'deal_lost'
);;
