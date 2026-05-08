create or replace function public.exec_sql_falconcrm(query_falconcrm text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  begin
    execute format('with q as (%s) select coalesce(jsonb_agg(row_to_json(q)), ''[]''::jsonb) from q', query_falconcrm)
      into result;
    return coalesce(result, '[]'::jsonb);
  exception when others then
    execute query_falconcrm;
    return '[]'::jsonb;
  end;
end;
$$;;
