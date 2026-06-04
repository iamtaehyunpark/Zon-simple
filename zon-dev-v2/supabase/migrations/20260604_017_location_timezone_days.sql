-- 017 — Location-timezone day bucketing. Applied via MCP 2026-06-04.
-- Each check-in/stamp records the device UTC offset at creation (its location's
-- timezone). Days are bucketed by that offset, not the viewer's device tz.
alter table public.check_ins add column tz_offset_min int not null default 540;
alter table public.stamps    add column tz_offset_min int not null default 540;

create or replace function public.check_ins_for_local_day(p_date date)
returns setof public.check_ins language sql stable set search_path = '' as $$
  select * from public.check_ins
  where user_id = (select auth.uid())
    and ((visited_at at time zone 'UTC') + make_interval(mins => tz_offset_min))::date = p_date
  order by visited_at asc;
$$;

create or replace function public.stamps_for_local_day(p_date date)
returns setof public.stamps language sql stable set search_path = '' as $$
  select * from public.stamps
  where user_id = (select auth.uid())
    and ((visited_at at time zone 'UTC') + make_interval(mins => tz_offset_min))::date = p_date
  order by visited_at asc;
$$;

create or replace function public.monthly_visit_counts(p_year int, p_month int)
returns table(day int, cnt int) language sql stable set search_path = '' as $$
  with visits as (
    select ((visited_at at time zone 'UTC') + make_interval(mins => tz_offset_min))::date as d
      from public.check_ins where user_id = (select auth.uid())
    union all
    select ((visited_at at time zone 'UTC') + make_interval(mins => tz_offset_min))::date as d
      from public.stamps
      where user_id = (select auth.uid()) and check_in_id is null
  )
  select extract(day from d)::int as day, count(*)::int as cnt
  from visits
  where extract(year from d) = p_year and extract(month from d) = p_month
  group by d;
$$;
