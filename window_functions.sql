---------------------------------------- Window Functions ----------------------------------------

--*-*-*-* RANK *-*-*-*--

-- Return rank of each constructor by points scored
select 
    constructorid,
    points,
    rank() over (order by points desc) as rank
from constructor_results
;

-- Rank races by date (earliest date ranked 1)
select
    raceid,
    name,
    date,
    rank() over (order by date asc) as date_rank
from races
;

-- Rank races table, ranking each race separately (using name)
select
    raceid,
    name,
    date,
    rank() over (partition by name order by date asc) as date_rank
from races
;

-- 1. Get total # races in which each driver has competed for each constructor
-- 2. For each constructor, rank drivers by # races they've completed for that constructor (dense rank)
-- 3. Create primary key
select 
    constructorid,
    driverid,
    count(distinct raceid) as num_races,
    dense_rank() over (partition by constructorid order by num_races desc) as races_rank,
    row_number() over (order by driverid, constructorid desc) as pkey
from results
group by
    driverid,
    constructorid
order by
    constructorid,
    num_races desc
;

---------- (Skipped slides) ----------

--*-*-*-* FIRST_VALUE *-*-*-*--

-- Return orders table w/ column containing first date on which product was ordered
select
    *,
    first_value(order_date) over (partition by product_id order by order_date asc) as first_order_date
from orders
order by
    product_id,
    order_date asc
;

--*-*-*-* LAST_VALUE *-*-*-*--

-- Return orders table w/ column containing last date on which product was ordered
select
    *,
    first_value(order_date) over (partition by product_id order by order_date desc) as last_order_date
from orders
order by
    product_id,
    order_date desc
;

--------------------------------------

--*-*-*-* LAG *-*-*-*--

-- Find days elapsed btwn each race (name) and last time race was conducted
select 
    *,
    datediff('day', lag(date, 1) over (partition by name order by date asc), date) as days_elapsed
from races
order by
    name,
    year asc
;

--*-*-*-* LEAD *-*-*-*--

-- Use driver_standings to find # points each driver has more than the driver 1 behind them in standings
-- Return raceid, position, driverid, points, next_driver_points, diff
select 
    raceid,
    position,
    driverid,
    points,
    lead(points, 1) over (partition by raceid order by position asc) as behind_driver_points,
    points - behind_driver_points as diff
from driver_standings
order by 
    raceid,
    position asc
;

-- Using constructor_results to find:
-- 1. total points across all races for each constructor 
-- 2. rank of each constructor by total points scored
-- 3. point margin btwn each constructor and constructor 1 behind them in ranking
select 
    constructorid,
    sum(points) as total_points,
    rank() over (order by total_points desc) as constructor_rank,
    total_points - lead(total_points, 1) over (order by total_points desc) as point_margin
from constructor_results
group by all
order by constructor_rank
;

--*-*-*-* INTERPOLATE_F/BFILL *-*-*-*--

-- Fill in missing stock prices w/ nearest non-null prior values of same stock
select
    *,
    interpolate_ffill(close_price) over (partition by index_id order by date) as filled_price
from stock_prices
;

-- Fill in missing temperature values w/ nearby values from same sensor (direction dnm)
select
    *,
    interpolate_ffill(temp_f) over (partition by sensor_id order by reading_ts) as filled_temp
from sensor_readings
;

--*-*-*-* QUALIFY *-*-*-*--

-- Use QUALIFY to deduplicate website_traffic, activity_id should be unique
select *
from website_traffic
qualify row_number() over (partition by activity_id order by event_timestamp) = 1 -- groups rows into buckets based on activity_id, then keeps first one only (1 repeats for each activity_id)
order by activity_id
;

-- Calculate total # races for each constructor, only inclue top 10 constructors based on this
select
    constructorid,
    count(distinct raceid) as total_races,
    rank() over (order by total_races desc) as rank
from constructor_standings
group by all
qualify rank <= 10
;

-- Return all results from drivers who scored more points in that race than their previous
-- Tables: results, races
select
  driverid,
  name,
  date,
  rs.raceid,
  lag(points, 1) over (partition by driverid order by date asc) as prev_race_points,
  points
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
qualify points > prev_race_points
;

--*-*-*-* AGGREGATIONS *-*-*-*--

-- Return races table + column for earliest year that race was conducted
-- With CTE
with earliest_years as
(
    select 
        raceid,
        min(year) as year
    from races
    group by raceid
)
select 
    *,
    e.year as earliest_year
from races as r
    inner join earliest_years as e
        on r.raceid = e.raceid
;

-- Return races table + column for earliest year that race was conducted
-- With window function
select
    *,
    min(year) over (partition by raceid order by year) as earliest_year
from races
;

-- Using results table, create boolean field indicating whether each result is better than that driver's avg finish position
select
    *,
    avg(position) over (partition by driverid) as avg_position,
    position < avg_position as better_than_avg -- < b/c higher position closer to 1
from results
;

-- Return races table + column w/ total # races in F1 history
select 
    *,
    count(*) over () as total_races
from races
;

--*-*-*-* RUNNING CALCULATIONS (SUM, AVG, COUNT) *-*-*-*--

-- Using pit_stops, find running total of seconds spent during pit stops for each driver in each race
select 
    *,
    sum(milliseconds / 1000) over (partition by raceid, driverid order by stop asc) as running_total_s
from pit_stops
order by
    raceid,
    driverid,
    stop asc
;

-- Using results and races, find running avg of points for each driver per year
select
    year,
    rs.driverid,
    sum(points) as yearly_points, -- need for running avg (check output)
    avg(yearly_points) over (partition by driverid order by year) as running_avg
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
group by all
order by
    driverid,
    year asc
;

-- Using results and races, get running count of races in which each driver has competed across their whole career
select
    rc.date,
    driverid,
    count(*) over (partition by driverid order by rc.date) as running_count_races -- driver buckets - count # dates
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
order by
    driverid,
    rc.date
;

-- Using results and races, for each driver find:
-- 1. whether that race was better or worse than avg finish (based on position)
-- 2. running sum of wins
-- 3. # days btwn first and most recent race
select
    driverid,
    date,
    avg(position) over (partition by driverid) as avg_finish_pos,
    position,
    position < avg_finish_pos as better_than_avg,
    sum(iff(position = 1, 1, 0)) over (partition by driverid order by date asc) as running_sum_wins,
    first_value(date) over (partition by driverid order by date) as first_date,
    last_value(date) over (partition by driverid order by date) as last_date,
    datediff('day', first_date, last_date) as days_btwn_first_last
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
order by
    driverid,
    date
;

--*-*-*-* MOVING CALCULATIONS *-*-*-*--

-- Using results and races, get 4 yr moving avg in annual points scored per driver 
-- btwn current year and 3 prior
select
    year,
    driverid,
    sum(points) as yearly_points, -- needed
    avg(yearly_points) over (partition by driverid order by year asc rows between 3 preceding and current row) as four_yr_moving_avg
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
group by all
order by
    driverid,
    year
;

-- Using results and races, find results where drivers scored more points than they'd scored in prior 3 races put together
select 
    date,
    driverid,
    points,
    sum(points) over (partition by driverid order by date rows between 3 preceding and 1 preceding) as prior_3_races_points
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
qualify points > prior_3_races_points
order by
    driverid,
    date
;