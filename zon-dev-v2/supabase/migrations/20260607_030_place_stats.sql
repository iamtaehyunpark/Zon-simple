-- place_stats view: aggregates public stamps into per-place statistics.
-- Used by Phase C (hot places cluster) and Phase E (nearby hot list).

set search_path = '';

create or replace view public.place_stats as
select
  external_place_id,
  external_source,
  normalized_place_name,
  max(place_name)                           as place_name,
  avg(lat)                                  as lat,
  avg(lng)                                  as lng,
  count(distinct id)                        as stamp_count,
  count(distinct user_id)                   as visitor_count,
  max(visited_at)                           as last_visit,
  -- hot_score: log-scaled stamp count, decayed by days since last visit
  (
    ln(count(distinct id) + 1)
    * (1.0 / (
        extract(epoch from now() - max(visited_at)) / 86400.0 + 1
       ))
  )                                         as hot_score
from public.stamps
where visibility = 'public'
  and external_place_id is not null
group by external_place_id, external_source, normalized_place_name;

-- Allow authenticated users to read the view.
grant select on public.place_stats to authenticated;
