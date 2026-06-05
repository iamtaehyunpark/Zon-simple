-- 022 — Exclude passive 'auto' check-ins from calendar visit counts. 2026-06-05.
create or replace function public.monthly_visit_counts(p_year int, p_month int)
returns table(day int, cnt int) language sql stable set search_path = '' as $$
  with visits as (
    select (visited_at at time zone 'UTC')::date as d
      from public.check_ins
      where user_id = (select auth.uid()) and source <> 'auto'
    union all
    select (visited_at at time zone 'UTC')::date as d
      from public.stamps
      where user_id = (select auth.uid()) and check_in_id is null
  )
  select extract(day from d)::int as day, count(*)::int as cnt
  from visits
  where extract(year from d) = p_year and extract(month from d) = p_month
  group by d;
$$;
