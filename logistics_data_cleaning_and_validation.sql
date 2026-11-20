-- LOGISTICS COST ANALYSIS: DATA INSPECTING, CLEANING & VALIDATION
-- Schema: case2_logistic | Periods: H2-2024 (Jul-Dec 2024) vs H1-2025 (Jan-Jun 2025)
-- Tables: dim_date, dim_hub, dim_vendor, fact_delivery_cost, fact_delivery_performance,
--         fact_rider_hub_productivity, fact_vendor_performance

-- Contents:
--   I.   Grain Identification
--   II.  Nulls, Range and Logic Checks
--   III. Referential Integrity and Date Coverage
--   IV.  Anomaly Handling: late_deliveries / on_time_deliveries
--   V.   Cross-table Reconciliation
--   VI.  Validation Queries for the Dashboard and Story
--   VII. Limitations and Notes
--
-- Note: no rows are deleted. Anomalies are flagged and documented (see IV and VII).

-- I. Grain Identification

-- 1. dim_date Table - Grain: date_key

select
    count(*) as total_rows,
    count (distinct date_key) as grain_check
from case2_logistic.dim_date dd ;
-- Result:
--	total_rows	grain_check
--	365	365

-- 2. dim_hub Table - Grain: hub_id

select
    count(*) as total_rows,
    count (distinct hub_id) as grain_check
from case2_logistic.dim_hub dh ;
-- Result:
-- total_rows	grain_check
-- 10	10

-- 3. dim_vendor Table - Grain: vendor_id

select
    count(*) as total_rows,
    count (distinct vendor_id) as grain_check
from case2_logistic.dim_vendor dv ;
-- Result:
-- total_rows	grain_check
-- 3	3

-- 4. fact_delivery_cost Table - Grain: date × hub_id × service_type × route_type × payment_type × size_type 
-- distinct rows
select
	(select count(*) from case2_logistic.fact_delivery_cost fdc) as n_rows,
	(select count(*) from 
		(select distinct date, hub_id, service_type, route_type, payment_type, size_type 
		from case2_logistic.fact_delivery_cost fdc) x) as n_distinct_grains;
-- Result:
-- n_rows	n_distinct_grains
-- 58,400	58,400
 -- hub x day
select 
	n_per_hub_day, 
	count(*) as n_hub_days
from (select date, hub_id, count(*) as n_per_hub_day
      from case2_logistic.fact_delivery_cost fdc
      group by date, hub_id) t
group by n_per_hub_day;
-- Result:
-- n_per_hub_day	n_hub_days
-- 16	3,650

-- variables row checks
select 'service_type' as dim, service_type as val, count(*) as n from case2_logistic.fact_delivery_cost fdc group by service_type
union all
select 'route_type', route_type, count(*) from case2_logistic.fact_delivery_cost fdc group by route_type
union all
select 'payment_type', payment_type, count(*) from case2_logistic.fact_delivery_cost fdc group by payment_type
union all
select 'size_type', size_type, count(*) from case2_logistic.fact_delivery_cost fdc group by size_type
union all
select 'hub_id', hub_id, count(*) from case2_logistic.fact_delivery_cost fdc group by hub_id;


-- 5. fact_delivery_performance Table - Grain: date × hub_id × service_type × route_type × payment_type × size_type 

select
	(select count(*) from case2_logistic.fact_delivery_performance fdp) as n_rows,
	(select count(*) from 
		(select distinct date, hub_id, service_type, route_type, payment_type, size_type 
		from case2_logistic.fact_delivery_performance fdp) x) as n_distinct_grains;
-- Result:
-- n_rows	n_distinct_grains
-- 58,400	58,400

 -- hub x day
select 
	n_per_hub_day, 
	count(*) as n_hub_days
from (select date, hub_id, count(*) as n_per_hub_day
      from case2_logistic.fact_delivery_performance fdp
      group by date, hub_id) t
group by n_per_hub_day;
-- Result:
-- n_per_hub_day	n_hub_days
-- 16	3,650

-- variables row checks
select 'service_type' as dim, service_type as val, count(*) as n from case2_logistic.fact_delivery_performance fdp group by service_type
union all
select 'route_type', route_type, count(*) from case2_logistic.fact_delivery_performance fdp group by route_type
union all
select 'payment_type', payment_type, count(*) from case2_logistic.fact_delivery_performance fdp group by payment_type
union all
select 'size_type', size_type, count(*) from case2_logistic.fact_delivery_performance fdp group by size_type
union all
select 'hub_id', hub_id, count(*) from case2_logistic.fact_delivery_performance fdp group by hub_id;

-- key variables check fact_delivery_cost and fact_delivery_performance
select
	(select count(*)
	 from case2_logistic.fact_delivery_performance p
	 left join case2_logistic.fact_delivery_cost c
	   on p.date = c.date and p.hub_id = c.hub_id and p.service_type = c.service_type
	  and p.route_type = c.route_type and p.payment_type = c.payment_type and p.size_type = c.size_type
	 where c.date is null) as in_perf_not_in_cost,
	(select count(*)
	 from case2_logistic.fact_delivery_cost c
	 left join case2_logistic.fact_delivery_performance p
	   on p.date = c.date and p.hub_id = c.hub_id and p.service_type = c.service_type
	  and p.route_type = c.route_type and p.payment_type = c.payment_type and p.size_type = c.size_type
	 where p.date is null) as in_cost_not_in_perf;
-- Result:
-- in_perf_not_in_cost	in_cost_not_in_perf
-- 0	0

-- 6. fact_rider_hub_productivity Table - Grain: date × hub_id

-- rows count
select
	(select count(*) from case2_logistic.fact_rider_hub_productivity) as n_rows,
	(select count(*) from
		(select distinct date, hub_id
		from case2_logistic.fact_rider_hub_productivity) x) as n_distinct_grains;
-- Result:
-- n_rows	n_distinct_grains
-- 3,650	3,650

-- number of hubs per day 
select
	n_per_hub_day,
	count(*) as n_hub_days
from (select date, hub_id, count(*) as n_per_hub_day
      from case2_logistic.fact_rider_hub_productivity
      group by date, hub_id) t
group by n_per_hub_day;
-- Result:
-- n_per_hub_day	n_hub_days
-- 1	3,650

-- hub x days
select hub_id, count(*) as n_rows, count(distinct date) as n_days
from case2_logistic.fact_rider_hub_productivity
group by hub_id;

-- 365

-- 7. fact_vendor_performance Table - Grain: date × hub_id × vendor_id

select
	(select count(*) from case2_logistic.fact_vendor_performance) as n_rows,
	(select count(*) from
		(select distinct date, hub_id, vendor_id
		from case2_logistic.fact_vendor_performance) x) as n_distinct_grains;
-- Result:
-- n_rows	n_distinct_grains
-- 10,950	10,950
select
	n_per_hub_day,
	count(*) as n_hub_days
from (select date, hub_id, count(*) as n_per_hub_day
      from case2_logistic.fact_vendor_performance
      group by date, hub_id) t
group by n_per_hub_day;
-- Result:
-- n_per_hub_day	n_hub_days
-- 3	3,650

select 'vendor_id' as dim, vendor_id as val, count(*) as n
from case2_logistic.fact_vendor_performance group by vendor_id
union all
select 'hub_id', hub_id, count(*)
from case2_logistic.fact_vendor_performance group by hub_id;

select
	(select count(*) from
		(select distinct date, hub_id from case2_logistic.fact_delivery_performance) p
	 left join case2_logistic.fact_rider_hub_productivity r
	   on p.date = r.date and p.hub_id = r.hub_id
	 where r.date is null) as perf_not_in_productivity,
	(select count(*) from
		(select distinct date, hub_id from case2_logistic.fact_delivery_performance) p
	 left join (select distinct date, hub_id from case2_logistic.fact_vendor_performance) v
	   on p.date = v.date and p.hub_id = v.hub_id
	 where v.date is null) as perf_not_in_vendor;
-- Result:
-- 0 0 

-- II. Nulls, Range and Logic Checks

-- 1. fact_delivery_cost Table

select
	sum(case when labor_cost is null then 1 else 0 end) as null_labor,
	sum(case when transportation_cost is null then 1 else 0 end) as null_transport,
	sum(case when hub_handling_cost is null then 1 else 0 end) as null_hub,
	sum(case when failed_redelivery_cost is null then 1 else 0 end) as null_failed,
	sum(case when outsourcing_cost is null then 1 else 0 end) as null_outsourcing,
	sum(case when total_delivery_cost is null then 1 else 0 end) as null_total,
	sum(case when labor_cost < 0 or transportation_cost < 0 or hub_handling_cost < 0
	          or failed_redelivery_cost < 0 or outsourcing_cost < 0 or total_delivery_cost < 0
	         then 1 else 0 end) as n_negative,
	sum(case when abs(total_delivery_cost - (labor_cost + transportation_cost + hub_handling_cost
	          + failed_redelivery_cost + outsourcing_cost)) > 1 then 1 else 0 end) as n_total_mismatch
from case2_logistic.fact_delivery_cost;
-- Result:0

-- 2. fact_delivery_performance
-- There are 9889 negative values in late_deliveries
select
	sum(case when shipment_volume is null or successful_deliveries is null or on_time_deliveries is null
	          or late_deliveries is null or outsourced_shipments is null or internal_shipments is null
	         then 1 else 0 end) as n_null_rows,
	sum(case when shipment_volume <= 0 then 1 else 0 end) as n_volume_le_0,
	sum(case when shipment_volume <> outsourced_shipments + internal_shipments then 1 else 0 end) as n_vol_neq_out_plus_int,
	sum(case when successful_deliveries > shipment_volume then 1 else 0 end) as n_success_gt_volume,
	sum(case when on_time_deliveries > successful_deliveries then 1 else 0 end) as n_ontime_gt_success,
	sum(case when late_deliveries < 0 then 1 else 0 end) as n_late_negative,
	sum(case when on_time_deliveries + late_deliveries <> successful_deliveries then 1 else 0 end) as n_ontime_plus_late_neq_success,
	sum(case when first_attempt_failed_shipments > shipment_volume then 1 else 0 end) as n_fail_gt_volume
from case2_logistic.fact_delivery_performance;
-- Result: n_late_negative = 9889, n_ontime_gt_success 9889

-- 3. fact_rider_hub_productivity

select
	sum(case when rider_count is null or hub_staff_count is null or working_hours is null
	          or internal_shipments is null or hub_capacity is null then 1 else 0 end) as n_null_rows,
	sum(case when rider_count <= 0 then 1 else 0 end) as n_rider_le_0,
	sum(case when capacity_utilization > 1 then 1 else 0 end) as n_util_gt_1,
	sum(case when misroute_rate < 0 or misroute_rate > 1 then 1 else 0 end) as n_misroute_out_of_range,
	sum(case when overtime_hours > working_hours then 1 else 0 end) as n_ot_gt_work,
	sum(case when successful_deliveries > internal_shipments then 1 else 0 end) as n_success_gt_internal,
	sum(case when internal_shipments > hub_capacity then 1 else 0 end) as n_internal_gt_capacity
from case2_logistic.fact_rider_hub_productivity; 
-- Result: 

-- n_null_rows	n_rider_le_0	n_util_gt_1	n_misroute_out_of_range	n_ot_gt_work	n_success_gt_internal	n_internal_gt_capacity
-- 0	0	543	0	0	3,650	543

-- Note: capacity_utilization > 1 is expected at the three overloaded hubs (see VI.5), not a data error.

-- 4. fact_vendor_performance

select
	sum(case when outsourced_shipments is null or vendor_cost is null
	          or vendor_on_time_deliveries is null or vendor_first_attempt_failed_shipments is null
	         then 1 else 0 end) as n_null_rows,
	sum(case when outsourced_shipments <= 0 then 1 else 0 end) as n_shipments_le_0,
	sum(case when vendor_cost <= 0 then 1 else 0 end) as n_cost_le_0,
	sum(case when vendor_on_time_deliveries > outsourced_shipments then 1 else 0 end) as n_ontime_gt_shipments,
	sum(case when vendor_first_attempt_failed_shipments > outsourced_shipments then 1 else 0 end) as n_fail_gt_shipments
from case2_logistic.fact_vendor_performance;
-- Result: 0


-- III. Referential Integrity and Date Coverage

-- 1. Keys that are not in the dimension tables (expected: 0 for every row)
select 'cost: hub not in dim_hub' as chk, count(distinct f.hub_id) as n
from case2_logistic.fact_delivery_cost f
left join case2_logistic.dim_hub h on f.hub_id = h.hub_id
where h.hub_id is null
union all
select 'performance: hub not in dim_hub', count(distinct f.hub_id)
from case2_logistic.fact_delivery_performance f
left join case2_logistic.dim_hub h on f.hub_id = h.hub_id
where h.hub_id is null
union all
select 'productivity: hub not in dim_hub', count(distinct f.hub_id)
from case2_logistic.fact_rider_hub_productivity f
left join case2_logistic.dim_hub h on f.hub_id = h.hub_id
where h.hub_id is null
union all
select 'vendor: hub not in dim_hub', count(distinct f.hub_id)
from case2_logistic.fact_vendor_performance f
left join case2_logistic.dim_hub h on f.hub_id = h.hub_id
where h.hub_id is null
union all
select 'vendor: vendor not in dim_vendor', count(distinct f.vendor_id)
from case2_logistic.fact_vendor_performance f
left join case2_logistic.dim_vendor v on f.vendor_id = v.vendor_id
where v.vendor_id is null
union all
select 'cost: date not in dim_date', count(distinct f.date)
from case2_logistic.fact_delivery_cost f
left join case2_logistic.dim_date d on f.date = d.date
where d.date is null
union all
select 'performance: date not in dim_date', count(distinct f.date)
from case2_logistic.fact_delivery_performance f
left join case2_logistic.dim_date d on f.date = d.date
where d.date is null
union all
select 'productivity: date not in dim_date', count(distinct f.date)
from case2_logistic.fact_rider_hub_productivity f
left join case2_logistic.dim_date d on f.date = d.date
where d.date is null
union all
select 'vendor: date not in dim_date', count(distinct f.date)
from case2_logistic.fact_vendor_performance f
left join case2_logistic.dim_date d on f.date = d.date
where d.date is null;
-- Result: 0

-- 2. Date coverage and half_year consistency
select half_year,
	min(date) as first_date,
	max(date) as last_date,
	count(distinct date) as n_days
from case2_logistic.fact_delivery_performance
group by half_year
order by half_year;
-- Result:  2024-07-01 - 2024-12-31 (H2_2024) and 2025-01-01 - 2025-06-30 (H1_2025), no missing days


-- IV. Anomaly Handling: late_deliveries / on_time_deliveries

-- late_deliveries - negative values 
-- on_time > successful_deliveries => FLAGGED (not deleted)

select half_year,
	count(*) as n_rows,
	sum(case when on_time_deliveries > successful_deliveries then 1 else 0 end) as n_weird_metrics,
	sum(case when on_time_deliveries > shipment_volume then 1 else 0 end) as n_ontime_gt_volume,
	sum(case when on_time_deliveries + late_deliveries <> successful_deliveries then 1 else 0 end) as n_identity_broken,
	sum(on_time_deliveries) * 1.0 / sum(successful_deliveries) as otd_raw,
	sum(case when on_time_deliveries > successful_deliveries then successful_deliveries
	         else on_time_deliveries end) * 1.0 / sum(successful_deliveries) as otd_capped
from case2_logistic.fact_delivery_performance
group by half_year;
-- Result: 
-- half_year	n_rows	n_weird_metrics	n_ontime_gt_volume	n_identity_broken	otd_raw	otd_capped
-- H1_2025	28,960	5,430	4,887	0	0.9401416516	0.926718236
-- H2_2024	29,440	4,459	4,352	0	0.9306234081	0.9211863981


-- segment figuring: express-urban-prepaid-small / standard-urban-prepaid-small / express-urban-COD-small
select service_type, route_type, payment_type, size_type,
	count(*) as n_rows,
	sum(case when on_time_deliveries > successful_deliveries then 1 else 0 end) as n_bad
from case2_logistic.fact_delivery_performance
group by service_type, route_type, payment_type, size_type
order by n_bad desc;

-- V. Cross-table Reconciliation

-- 1. fact_rider_hub_productivity vs fact_delivery_performance (hub x day)
select r.half_year,
	count(*) as n_hub_days,
	max(abs(r.internal_shipments - p.internal)) as max_diff_internal,
	max(abs(r.successful_deliveries - p.successful)) as max_diff_success
from case2_logistic.fact_rider_hub_productivity r
join (select date, hub_id,
	         sum(internal_shipments) as internal,
	         sum(successful_deliveries) as successful
	  from case2_logistic.fact_delivery_performance
	  group by date, hub_id) p
  on r.date = p.date and r.hub_id = p.hub_id
group by r.half_year;
-- Result:
-- half_year	n_hub_days	max_diff_internal	max_diff_success
-- H1_2025	1,810	0	0
-- H2_2024	1,840	0	0

-- 2. Cost formula's consistency (total = sum of components)
select *
from case2_logistic.fact_delivery_cost
where total_delivery_cost <>
      labor_cost + transportation_cost + hub_handling_cost + failed_redelivery_cost + outsourcing_cost;

-- 3. Shipment volume = internal + outsourced (by half-year)
select
    half_year,
    count(*) as total_records,

    sum(shipment_volume) as total_shipments,
    sum(internal_shipments) as internal_shipments,
    sum(outsourced_shipments) as outsourced_shipments,

    sum(internal_shipments + outsourced_shipments)
        as combined_shipments,

    sum(shipment_volume)
        - sum(internal_shipments + outsourced_shipments)
        as volume_difference,

    sum(case
        when shipment_volume <> internal_shipments + outsourced_shipments
        then 1 else 0
    end) as mismatched_records

from case2_logistic.fact_delivery_performance
group by half_year
order by half_year;
-- Result:
-- half_year	total_records	total_shipments	internal_shipments	outsourced_shipments	combined_shipments	volume_difference	mismatched_records
-- H1_2025	28,960	5,400,000	4,447,200	952,800	5,400,000	0	0
-- H2_2024	29,440	5,000,000	4,477,600	522,400	5,000,000	0	0

-- 4. Vendor tables vs cost and performance tables (outsourced volume and cost should match)
select
	(select sum(vendor_cost) from case2_logistic.fact_vendor_performance) as vendor_cost_total,
	(select sum(outsourcing_cost) from case2_logistic.fact_delivery_cost) as outsourcing_cost_total,
	(select sum(outsourced_shipments) from case2_logistic.fact_vendor_performance) as vendor_shipments,
	(select sum(outsourced_shipments) from case2_logistic.fact_delivery_performance) as perf_outsourced;
-- Result:
-- vendor_cost_total	outsourcing_cost_total	vendor_shipments	perf_outsourced
-- 236,000,000,000	236,000,000,000	1,475,200	1,475,200

-- VI. Validation Queries for the Dashboard and Story
-- Each query reproduces a figure used in the dashboard / executive summary / storytelling.

-- 1. Cost by component and half-year (cost decomposition and share of each component)
select half_year,
	sum(labor_cost) as labor,
	sum(transportation_cost) as transportation,
	sum(hub_handling_cost) as hub_handling,
	sum(failed_redelivery_cost) as failed_redelivery,
	sum(outsourcing_cost) as outsourcing,
	sum(total_delivery_cost) as total,
	round(100.0 * sum(outsourcing_cost) / sum(total_delivery_cost), 2) as outsourcing_share_pct,
	round(100.0 * sum(labor_cost + transportation_cost + hub_handling_cost) / sum(total_delivery_cost), 2) as internal_share_pct,
	round(100.0 * sum(failed_redelivery_cost) / sum(total_delivery_cost), 2) as failed_share_pct
from case2_logistic.fact_delivery_cost
group by half_year
order by half_year;
-- Result: 
-- half_year	labor	transportation	hub_handling	failed_redelivery	outsourcing	total	outsourcing_share_pct	internal_share_pct	failed_share_pct
-- H1_2025	180,573,063,740	175,821,141,010	118,798,068,250	18,807,727,000	156,000,000,000	650,000,000,000	24	73.11	2.89
-- H2_2024	155,502,751,080	151,410,573,420	102,304,441,500	10,782,234,000	80,000,000,000	500,000,000,000	16	81.84	2.16

-- 2. Volume, outsourced share and OTD by half-year
select half_year,
	sum(shipment_volume) as volume,
	sum(internal_shipments) as internal,
	sum(outsourced_shipments) as outsourced,
	round(100.0 * sum(outsourced_shipments) / sum(shipment_volume), 2) as outsourced_share_pct,
	round(100.0 * sum(on_time_deliveries) / sum(successful_deliveries), 2) as otd_raw_pct
from case2_logistic.fact_delivery_performance
group by half_year
order by half_year;
-- Result: 
-- half_year	volume	internal	outsourced	outsourced_share_pct	otd_raw_pct
-- H1_2025	5,400,000	4,447,200	952,800	17.64	94.01
-- H2_2024	5,000,000	4,477,600	522,400	10.45	93.06

-- 3. Volume effect (cost increase explained by volume growth at the H2-2024 cost per shipment)
with agg as (
	select c.half_year, c.cost, p.vol
	from (select half_year, sum(total_delivery_cost) as cost
	      from case2_logistic.fact_delivery_cost group by half_year) c
	join (select half_year, sum(shipment_volume) as vol
	      from case2_logistic.fact_delivery_performance group by half_year) p
	  on c.half_year = p.half_year
)
select
	sum(case when half_year = 'H2_2024' then cost end) as cost_h2,
	sum(case when half_year = 'H1_2025' then cost end) as cost_h1,
	sum(case when half_year = 'H1_2025' then cost end)
		- sum(case when half_year = 'H2_2024' then cost end) as cost_increase,
	sum(case when half_year = 'H2_2024' then cost end)
		* (sum(case when half_year = 'H1_2025' then vol end) * 1.0
		   / sum(case when half_year = 'H2_2024' then vol end) - 1) as volume_effect
from agg;
-- Result:
-- cost_h2	cost_h1	cost_increase	volume_effect
-- 500,000,000,000	650,000,000,000	150,000,000,000	40,000,000,000

-- 4. Shipment mix by route, payment, size and service (order mix check)
select 'route_type' as dim, route_type as val, half_year, sum(shipment_volume) as volume
from case2_logistic.fact_delivery_performance group by route_type, half_year
union all
select 'payment_type', payment_type, half_year, sum(shipment_volume)
from case2_logistic.fact_delivery_performance group by payment_type, half_year
union all
select 'size_type', size_type, half_year, sum(shipment_volume)
from case2_logistic.fact_delivery_performance group by size_type, half_year
union all
select 'service_type', service_type, half_year, sum(shipment_volume)
from case2_logistic.fact_delivery_performance group by service_type, half_year
order by 1, 2, 3;


-- 5. System-wide productivity and labor cost per head-day
select r.half_year,
	round(sum(r.internal_shipments) * 1.0 / nullif(sum(r.working_hours), 0), 2) as shipments_per_working_hour,
	round(sum(r.overtime_hours) * 100.0 / nullif(sum(r.working_hours), 0), 2) as ot_pct_of_hours,
	round(avg(r.rider_count), 0) as avg_daily_riders_per_hub,
	round(avg(r.hub_staff_count), 0) as avg_daily_hub_staff_per_hub
from case2_logistic.fact_rider_hub_productivity r
group by r.half_year
order by r.half_year;
-- Result: 
-- half_year	shipments_per_working_hour	ot_pct_of_hours	avg_daily_riders_per_hub	avg_daily_hub_staff_per_hub
-- H1_2025	7.32	13.68	42	7
-- H2_2024	7.86	7.5	39	7

select c.half_year,
	round(sum(c.labor_cost) / nullif(sum(r.rider_count + r.hub_staff_count), 0)) as labor_cost_per_head_day
from (select half_year, date, hub_id, sum(labor_cost) as labor_cost
      from case2_logistic.fact_delivery_cost
      group by half_year, date, hub_id) c
join case2_logistic.fact_rider_hub_productivity r
  on c.date = r.date and c.hub_id = r.hub_id
group by c.half_year
order by c.half_year;
-- Result: 
-- half_year	labor_cost_per_head_day
-- H1_2025	2,025,974
-- H2_2024	1,840,030

-- 7. Internal vs outsourcing cost per shipment
select
    half_year,

    sum(internal_shipments) as internal_shipments,
    sum(outsourced_shipments) as outsourced_shipments,

    sum(labor_cost
        + transportation_cost
        + hub_handling_cost) as internal_cost,

    sum(outsourcing_cost) as outsourcing_cost,

    sum(labor_cost
        + transportation_cost
        + hub_handling_cost)
        / nullif(sum(internal_shipments), 0)
        as internal_cost_per_shipment,

    sum(outsourcing_cost)
        / nullif(sum(outsourced_shipments), 0)
        as outsourcing_cost_per_shipment

from (
	select c.half_year, c.labor_cost, c.transportation_cost, c.hub_handling_cost, c.outsourcing_cost,
	       p.internal_shipments, p.outsourced_shipments
	from (select half_year, date, hub_id,
	             sum(labor_cost) as labor_cost, sum(transportation_cost) as transportation_cost,
	             sum(hub_handling_cost) as hub_handling_cost, sum(outsourcing_cost) as outsourcing_cost
	      from case2_logistic.fact_delivery_cost
	      group by half_year, date, hub_id) c
	join (select date, hub_id,
	             sum(internal_shipments) as internal_shipments,
	             sum(outsourced_shipments) as outsourced_shipments
	      from case2_logistic.fact_delivery_performance
	      group by date, hub_id) p
	  on c.date = p.date and c.hub_id = p.hub_id
) x
group by half_year
order by half_year;
-- Result: 
-- half_year	internal_shipments	outsourced_shipments	internal_cost	outsourcing_cost	internal_cost_per_shipment	outsourcing_cost_per_shipment
-- H1_2025	4,447,200	952,800	475,192,273,000	156,000,000,000	106,852.0131768304	163,727.959697733
-- H2_2024	4,477,600	522,400	409,217,766,000	80,000,000,000	91,392.2114525639	153,139.3568147014

-- 8. Hub level: cost per shipment and outsourced share
with c as (
	select half_year, hub_id, sum(total_delivery_cost) as cost
	from case2_logistic.fact_delivery_cost
	group by half_year, hub_id
),
p as (
	select half_year, hub_id, sum(shipment_volume) as vol, sum(outsourced_shipments) as outs
	from case2_logistic.fact_delivery_performance
	group by half_year, hub_id
)
select c.half_year, h.hub_name, p.vol,
	round(100.0 * p.outs / p.vol, 2) as outsourced_share_pct,
	round(c.cost / p.vol) as cost_per_shipment
from c
join p on c.half_year = p.half_year and c.hub_id = p.hub_id
join case2_logistic.dim_hub h on c.hub_id = h.hub_id
order by h.hub_name, c.half_year;


-- 9. Vendor level: volume, share, OTD, fail rate and cost per on-time delivery
-- (half_year derived from date so the query does not depend on a half_year column in this table)
with v as (
	select case when date >= '2025-01-01' then 'H1_2025' else 'H2_2024' end as half_year,
	       vendor_id, outsourced_shipments, vendor_cost,
	       vendor_on_time_deliveries, vendor_first_attempt_failed_shipments
	from case2_logistic.fact_vendor_performance
)
select v.half_year, dv.vendor_name,
	sum(v.outsourced_shipments) as shipments,
	round(100.0 * sum(v.outsourced_shipments)
		/ sum(sum(v.outsourced_shipments)) over (partition by v.half_year), 2) as share_pct,
	sum(v.vendor_cost) as vendor_cost,
	round(100.0 * sum(v.vendor_on_time_deliveries) / sum(v.outsourced_shipments), 2) as vendor_otd_pct,
	round(100.0 * sum(v.vendor_first_attempt_failed_shipments) / sum(v.outsourced_shipments), 2) as fail_rate_pct,
	round(sum(v.vendor_cost) / nullif(sum(v.vendor_on_time_deliveries), 0)) as cost_per_on_time_delivery
from v
join case2_logistic.dim_vendor dv on v.vendor_id = dv.vendor_id
group by v.half_year, dv.vendor_name
order by dv.vendor_name, v.half_year;

-- 10. Vendor mix at each hub (which vendors are used at the overloaded hubs)
with v as (
	select case when date >= '2025-01-01' then 'H1_2025' else 'H2_2024' end as half_year,
	       hub_id, vendor_id, outsourced_shipments
	from case2_logistic.fact_vendor_performance
)
select v.half_year, h.hub_name, dv.vendor_name,
	sum(v.outsourced_shipments) as shipments,
	round(100.0 * sum(v.outsourced_shipments)
		/ sum(sum(v.outsourced_shipments)) over (partition by v.half_year, h.hub_name), 2) as share_in_hub_pct
from v
join case2_logistic.dim_hub h on v.hub_id = h.hub_id
join case2_logistic.dim_vendor dv on v.vendor_id = dv.vendor_id
group by v.half_year, h.hub_name, dv.vendor_name
order by h.hub_name, v.half_year, dv.vendor_name;

-- 11. Failed delivery: first-attempt fail rate by payment type
select half_year, payment_type,
	round(100.0 * sum(first_attempt_failed_shipments) / sum(shipment_volume), 2) as first_attempt_fail_pct
from case2_logistic.fact_delivery_performance
group by half_year, payment_type
order by payment_type, half_year;

-- VII. Limitations and Notes

-- 1. late_deliveries / on_time_deliveries anomaly
--    9,889 rows have negative late_deliveries, and on_time_deliveries exceeds successful_deliveries
--    in a subset of segments (mainly small urban shipments: express prepaid, standard prepaid, express COD).
--    These rows are flagged (v_delivery_performance_flagged), not corrected or deleted.
--    The dashboard uses raw OTD; raw vs capped OTD is compared in IV so that the "SLA flat" conclusion
--    can be checked against the anomaly.

-- 2. No rows deleted
--    All grain, NULL, range and referential checks are reported only. Any adjustment would change
--    the totals reconciled in V and VI.

-- 3. Rates are weighted
--    OTD, fail rate and outsourced share are ratios of sums (weighted by volume), not averages of daily rates.
--    Measure definitions (e.g., shipments per rider, labor cost per head-day) should be aligned with
--    the Power BI measures before comparing figures one-to-one.

-- 4. Internal cost split
--    Labor, transportation and hub handling are taken as recorded in fact_delivery_cost. The transportation
--    increase cannot be explained further because the data has no distance, load or route metrics.

-- 5. Vendor selection
--    The data shows which vendors received volume (VI.9 and VI.10) but not why (e.g., regional coverage,
--    contract terms).

-- 6. Price effect
--    The vendor price effect combines contract price changes and a harder route / size mix; the data does not
--    separate the two.

-- 7. Period comparison
--    H2-2024 and H1-2025 are two half-year windows without a prior-year comparison, so seasonality
--    (e.g., year-end peak, Tet) is not controlled for.

-- 8. Case-study dataset
--    Findings illustrate the analytical approach and are not statements about a specific company.
