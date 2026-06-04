-- 018 — Fix day bucketing. Applied via MCP 2026-06-04.
-- visited_at is sent as DateTime.now().toIso8601String() (no offset), so the
-- local wall-clock numbers are stored as UTC — visited_at already encodes the
-- location's local time. Bucket by it directly; 017 erroneously added the
-- offset again, pushing evening check-ins to the next day.

create or replace function public.check_ins_for_local_day(p_date date)
returns setof public.check_ins language sql stable set search_path = '' as $$
  select * from public.check_ins
  where user_id = (select auth.uid())
    and (visited_at at time zone 'UTC')::date = p_date
  order by visited_at asc;
$$;

create or replace function public.stamps_for_local_day(p_date date)
returns setof public.stamps language sql stable set search_path = '' as $$
  select * from public.stamps
  where user_id = (select auth.uid())
    and (visited_at at time zone 'UTC')::date = p_date
  order by visited_at asc;
$$;

create or replace function public.monthly_visit_counts(p_year int, p_month int)
returns table(day int, cnt int) language sql stable set search_path = '' as $$
  with visits as (
    select (visited_at at time zone 'UTC')::date as d
      from public.check_ins where user_id = (select auth.uid())
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
