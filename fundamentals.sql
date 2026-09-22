--*-*-*-* SELECT *-*-*-*--

-- Return all unique ship modes per customer ID from Orders
select distinct
    ship_mode,
    customer_id
from orders
;

-- Return all unique ship modes per customer ID from Orders
-- but turn underscores -> spaces
select distinct
    ship_mode as "ship mode",
    customer_id as "customer id"
from orders
;

--*-*-*-* JOIN *-*-*-*--

-- Return all rows + columns customer_id matches in Orders & Customers
select *
from orders as o
    inner join customers as c
        on o.customer_id = c.customer_id
;

-- Produce list of all customers + sales reps so we can see:
-- sales reps w/o customers, and
-- customers w/o sales reps
select *
from customers as c
    full join customer_sales_rep as sr      -- full join bc includes leftover from left & right tables
        on c.customer_id = sr.customer_id
;

--*-*-*-* WHERE *-*-*-*--

-- Get all product sales btwn $50-$100 for orders shipped second class
select *
from orders
where
    sales between 50 and 100 and    -- use between instead of >= and <=
    ship_mode = 'Second Class'
;

-- Get all customers in cities ending in 'town'
select *
from customers
where city like '%town'
;

-- Get all customers in cities containing 'town' or 'city' (case insensitive)
select *
from customers
where 
    city ilike '%town%' or
    city ilike '%city%'
;

-- Get all customers in Texas, Oregon, New York
select *
from customers
where state in ('Texas', 'Oregon', 'New York')
;

--*-*-*-* GROUP BY *-*-*-*--

-- Get total sales made by company
select
    sum(sales) as total_sales
from orders
;

-- Get total sales per category
select
    category,
    sum(sales) as total_categorical_sales
from orders as o
    inner join products as p
        on o.product_id = p.product_id
group by category
;

-- Get distinct count of customers per state and sales person
select 
    state,
    sales_person_fullname,
    count(distinct c.customer_id) as distinct_customer_count
from customers as c
    inner join customer_sales_rep as sr
        on c.customer_id = sr.customer_id
group by all
;

-- Get largest discount and avg profit per state
select 
    state,
    max(discount) as max_discount,
    avg(profit) as avg_profit
from orders as o
    inner join customers as c
        on o.customer_id = c.customer_id
group by state
;

--*-*-*-* HAVING *-*-*-*--

-- Get customers w/ total sales > 10k from Orders & Customers
select
    c.customer_name,
    sum(sales) as total_sales
from orders as o
    inner join customers as c
        on o.customer_id = c.customer_id
group by c.customer_name
having sum(sales) > 10000
;

--*-*-*-* ORDER BY *-*-*-*--

-- Get customers w/ total sales > 10k, sorted by total sales desc
select
    c.customer_name,
    sum(sales) as total_sales
from orders as o
    inner join customers as c
        on o.customer_id = c.customer_id
group by c.customer_name
having sum(sales) > 10000
order by sum(sales) desc
;

--*-*-*-* CONCATENATION *-*-*-*--

-- Create column for 'city, state' for each customer
select
    *,
    city || ', ' || state as city_and_state
from customers
;

--*-*-*-* TYPE CASTING *-*-*-*--

-- Use both casting methods to convert postal_code for each customer -> varchar
select
    postal_code::varchar as casted_postal_code_1,
    cast(postal_code as varchar) as casted_postal_code_2
from customers
;

-- Convert columns to correct data types
select
    sales::float as sales,
    cost::float as cost,
    quantity::int as quantity,
    to_date(sale_date, 'MON DD, YYYY') as sale_date,
    to_date(ship_date, 'DD-MM-YYYY') as ship_date,
    is_online::boolean as is_online
from sales_table
;

-------------------------------------------------------
--=-=-=-= CHALLENGE: preppin data 2023 week 2 =-=-=-=--
-------------------------------------------------------

select 
    transaction_id,
    'GB' || check_digits || swift_code || replace(sort_code, '-', '') || account_number as iban
from pd2023_wk02_transactions as t
    inner join pd2023_wk02_swift_codes as sc
        on t.bank = sc.bank
;

-------------------------------------------------------
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-------------------------------------------------------

--*-*-*-* CASE *-*-*-*--

-- Create column grouping ship times in orders into 2 categories:
-- if shipped <= 3 days, 'fast'
-- else 'slow'
select
    *,
    case
        when datediff('day', order_date, ship_date) <= 3 then 'fast'
        else 'slow'
        end as ship_speed
from orders
;

-------------------------------------------------------
--=-=-=-= CHALLENGE: preppin data 2023 week 1 =-=-=-=--
-------------------------------------------------------

-- Output 1: Total values by bank
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    sum(value) as value
from pd2023_wk01
group by bank
;

-- Output 2: Total values by bank, day of week, type of transaction
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    case
        when online_or_in_person = 1 then 'Online'
        else 'In-Person'
        end as online_or_in_person,
    dayname(to_date(transaction_date, 'DD/MM/YYYY HH:MI:SS')) as transaction_date,
    sum(value) as value
from pd2023_wk01
group by all
;

-- Output 3: Total values by bank and customer code
select
    left(transaction_code, position('-', transaction_code, 1) - 1) as bank,
    customer_code,
    sum(value) as value
from pd2023_wk01
group by all
;

-------------------------------------------------------
--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--
-------------------------------------------------------

--*-*-*-* UNION *-*-*-*--

select *
from library_january
union
select *
from library_february
;

--*-*-*-* SUBQUERIES *-*-*-*--

-- (subquery in select)
-- List drivers & their fastest lap speeds at Monaco Grand Prix in 2021
-- Compare to fastest in Monaco of all time
-- Tables: results, races, drivers
select
    -- on driver level in 2021 at monaco
    max(rs.fastestlapspeed) as driver_max_speed_2021,
    d.forename as first_name,
    d.surname as last_name,
    (
        -- returns single fastest speed at monaco across all drivers & years
        select max(fastestlapspeed)
        from results as rs
            inner join races as rc
                on rs.raceid = rc.raceid
        where name = 'Monaco Grand Prix'
    ) as fastest_ever
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
    inner join drivers as d
        on rs.driverid = d.driverid
where
    name = 'Monaco Grand Prix'
    and year = 2021
group by 
    rs.driverid,
    d.forename,
    d.surname
order by max(rs.fastestlapspeed) desc
;

-- fastest_ever subquery on its own
select max(fastestlapspeed)
        from results as rs
            inner join races as rc
                on rs.raceid = rc.raceid
where name = 'Monaco Grand Prix'
;

-- (subquery in join/where)
-- List drivers at Monaco in 2021 + lifetime number of wins in Monaco
select
    d.forename as first_name,
    d.surname as last_name,
    wins.num_wins_in_monaco as num_wins_in_monaco
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
    inner join drivers as d
        on rs.driverid = d.driverid
    left join -- include drivers that never won in monaco
    (
        select
            driverid,
            count(driverid) as num_wins_in_monaco
        from results as rs
            inner join races as rc
                on rs.raceid = rc.raceid
        where
            name = 'Monaco Grand Prix' and
            position = 1
        group by driverid
    ) as wins
        on d.driverid = wins.driverid
where
    name = 'Monaco Grand Prix'
    and year = 2021
;

-- num_wins_in_monaco subquery on its own
-- every row is a driver
-- comes from rs and rc
select
    driverid,
    count(*) as num_wins_in_monaco
from results as rs
    inner join races as rc
        on rs.raceid = rc.raceid
where
    name = 'Monaco Grand Prix' and
    position = 1
group by driverid
order by num_wins_in_monaco desc
;

table results; -- raceid, driverid
table races; -- raceid
table drivers; -- driverid

--*-*-*-* CTEs *-*-*-*--

-- Create boolean column faster_than_avg
-- Indicates whether current pit stop was faster or slower than that driver's avg pit stop, in that race
with avg_pit_stops as
(
    -- avg pit stop per driver, per race
    select 
        raceid,
        driverid,
        avg(milliseconds) as avg_ms
    from pit_stops
    group by
        raceid,
        driverid
)
select
    ps.*,
    av.avg_ms,
    ps.milliseconds < av.avg_ms as faster_than_avg
from pit_stops as ps
    inner join avg_pit_stops as av
        on
            ps.raceid = av.raceid and
            ps.driverid = av.driverid
;

-- Return results table + column for total # wins for that driver
-- total wins per driver
with driver_wins as
(
    select
        driverid,
        count(*) as driver_total_wins
    from results
    where position = 1
    group by driverid
)
select
    rs.*, -- specify rs bc otherwise contains cte columns
    dw.driver_total_wins as driver_total_wins
from results as rs
    left join driver_wins as dw -- include all drivers, even those who never won
        on rs.driverid = dw.driverid
;

-- Calculate total # of points scored by each constructor (team) in each year they competed
-- Determine each constructor's best season even
-- Results should have 1 row per constructor per year
with constructor_yearly_points as
(
    -- total points per constructor per year
    select
        constructorid,
        year,
        sum(points) as yearly_points
    from results as rs
        inner join races as rc
            on rs.raceid = rc.raceid
    group by
        constructorid,
        year
),
constructor_best_season as
(
    -- max points per constructor
    select
        constructorid,
        max(yearly_points) as best_yearly_points
    from constructor_yearly_points
    group by constructorid
)
select 
    cyp.constructorid,
    year,
    yearly_points,
    best_yearly_points = yearly_points as is_best_season_ever
from constructor_yearly_points as cyp
    inner join constructor_best_season as bs
        on cyp.constructorid = bs.constructorid
;


-- Return results table with:
-- Column containing proportion of total race points earned by driver (pct_race_points)
-- Column containing proportion of driver's career points scored in that race (pct_career_points)
-- Exclude drivers with 0 career points
with total_race_points as 
(
    select
        raceid,
        sum(points) as race_points,
    from results
    group by raceid
),
total_career_points as 
(
    select
        driverid,
        sum(points) as career_points
    from results
    group by driverid
    having career_points > 0
)
select
    rs.*,
    points / race_points as pct_race_points,
    points / career_points as pct_career_points
from results as rs
    inner join total_race_points as rcp
        on rs.raceid = rcp.raceid
    inner join total_career_points as crp
        on rs.driverid = crp.driverid
;

--*-*-*-* Recursive CTEs *-*-*-*--

-- Generate all dates for 2026
-- still takes too long to run, doesn't display everything
with dates_2026 as
(
    select '2026-01-01'::date as current_date
    union all
    select dateadd('day', 1, current_date) as current_date
    from dates_2026
    where current_date < '2026-01-02' -- in place of 12-31
)
select *
from dates_2026
;

----------------------------------------------------------------------------------------------------
------------------------------------------ Skipped Slides ------------------------------------------
----------------------------------------------------------------------------------------------------

--*-*-*-* UNPIVOT *-*-*-*--

-- Unpivot (columns to rows)
select *
from pd2023_wk03_targets
    unpivot (value for quarter in (q1, q2, q3, q4))
;

-- Full challenge
-- targets: unpivot, rename fields, remove Q from quarter -> int
with targets as
(
    select
        online_or_in_person,
        right(quarter, 1)::int as quarter,
        value as quarterly_targets
    from pd2023_wk03_targets
        unpivot (value for quarter in (q1, q2, q3, q4))
),
-- transactions: only DSB, 1 -> Online & 2 -> In-Person, date -> quarter, sum by quarter & type of transaction
transactions as 
(
    select
        case
            when online_or_in_person = 1 then 'Online'
            else 'In-Person'
        end as online_or_in_person,
        quarter(to_date(transaction_date, 'DD/MM/YYYY HH:MI:SS')) as quarter,
        sum(value) as value
    from pd2023_wk01
    where transaction_code like 'DSB%'
    group by
        online_or_in_person,
        quarter
)
select
    tr.online_or_in_person,
    tr.quarter,
    tr.value,
    quarterly_targets,
    value - quarterly_targets as variance_to_target
from transactions as tr
    inner join targets as tg
        on
            tr.online_or_in_person = tg.online_or_in_person and
            tr.quarter = tg.quarter
;

table pd2023_wk01;
table pd2023_wk03_targets;

--*-*-*-* PIVOT *-*-*-*--

-- Pivot (rows to columns)
select *
from pd2023_wk04_january
    pivot (min(value) for demographic in ('Account Type', 'Date of Birth', 'Ethnicity'))
;

-- Full challenge
with all_months as
(
    select * from pd2023_wk04_january
    union
    select * from pd2023_wk04_february
    union
    select * from pd2023_wk04_march
    union
    select * from pd2023_wk04_april
    union
    select * from pd2023_wk04_may
    union
    select * from pd2023_wk04_june
    union
    select * from pd2023_wk04_july
    union
    select * from pd2023_wk04_august
    union
    select * from pd2023_wk04_september
    union
    select id, joining_day, demagraphic as demographic, value from pd2023_wk04_october
    union
    select * from pd2023_wk04_november
    union
    select * from pd2023_wk04_december
)
select *
from all_months
    pivot (min(value) for demographic in ('Account Type', 'Date of Birth', 'Ethnicity'))
;

---------------------- Appendix Challenges ----------------------

-- PD20222 WK03
with merged_table as
(
    select
        sc.*,
        st."gender"
    from pd2022_wk01 as st
        inner join pd2022_wk03 as sc -- not sure
            on st."id" = sc."Student ID"
),
pivoted_table as
(
    select
        "Student ID" as student_id,
        "gender" as gender,
        subject,
        score,
        iff(score >= 75, 1, 0) as passed
    from merged_table as m
        unpivot (score for subject in ("Maths", "English", "Spanish", "Science", "Art", "History", "Geography"))
)
select
    sum(passed) as passed_subjects,
    round(avg(score), 1) as avg_score,
    student_id,
    gender
from pivoted_table
group by
    student_id,
    gender
;

table pd2022_wk01;
table pd2022_wk03;

-- PD20222 WK01
select
    case
        when "Date of Birth" >= '2014-09-01' then 1
        when "Date of Birth" between '2013-09-01' and '2014-08-31' then 2
        when "Date of Birth" between '2012-09-01' and '2013-08-31' then 3
        else 4
    end as academic_year,
    "pupil last name" || ', ' || "pupil first name" as pupil_name,
    "pupil last name" || ', ' || iff("Parental Contact" = 1, "Parental Contact Name_1", "Parental Contact Name_2") as parental_contact_full_name,
    iff("Parental Contact" = 1, "Parental Contact Name_1", "Parental Contact Name_2") || '.' || "pupil last name" || '@' || "Preferred Contact Employer" || '.com' as parental_contact_email_address
from pd2022_wk01
;

table pd2022_wk01;