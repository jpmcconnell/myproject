select sum(CLOSED_WON_UW) as closed_won from salesops.cdavid_PACING_BASE
where Delivery_Qtr = '2014-10-01'
and Rep_Region__C is not null;

drop table temp1;

create volatile table temp1 as (
select distinct
Current_Date as cur_date,
CAST(((Current_Date - Delivery_Qtr)/7)as INT) as PACING_WEEK,
Delivery_Qtr,
Sales_Channel,
base.Rep_Region__C,
RR_GEO__C,
RR_Vertical__C,
LMS_Vertical,
sum(case when OPPTY_PRODUCT__C = 'Sponsored Updates' then CLOSED_WON_UW else 0 end) as SU,
sum(case when OPPTY_PRODUCT__C in ('Partner Messages', 'Partner Message', 'InMail', 'Sponsored InMail') then CLOSED_WON_UW else 0 end) as InMail,
sum(case when OPPTY_PRODUCT__C not in ('Partner Messages', 'Partner Message', 'InMail', 'Sponsored InMail','Sponsored Updates') then CLOSED_WON_UW else 0 end) as Disp, 
sum(bookedweighted) as weighted
from salesops.cdavid_PACING_BASE base
where base.Rep_Region__C is not null
and Delivery_Qtr = '2014-10-01' 
--and pacing_week between -12 and 13
group by 1,2,3,4,5,6,7,8)
with data no primary index on commit preserve rows;

create volatile table temp2 as (
select
t1.*,
PACING.BOOKED_AVG_PACE,
PACING.DISPLAY_BOOKED_PACE,
PACING.INMAIL_BOOKED_PACE,
PACING.SU_BOOKED_PACE,
PACING.WEIGHTED_AVG_PACE,
SU/PACING.SU_BOOKED_PACE as SU_Booked_Implied,
Disp/PACING.DISPLAY_BOOKED_PACE as Display_Booked_Implied,
InMail/PACING.INMAIL_BOOKED_PACE as InMail_Booked_Implied,
Weighted/PACING.WEIGHTED_AVG_PACE as Weighted_Implied,
SU_Booked_Implied + Display_Booked_Implied + InMail_Booked_Implied as Total_Booked_Implied
from temp1 t1
left join SalesOps.cdavid_PACING_REP_REGION_MAP RR on RR.Rep_Region__C = t1.Rep_Region__C 
left join SalesOps.cdavid_PACING_TIMING PACING on PACING.PACING_REGION = RR.Pacing_Rep_Region and PACING.PACING_WEEK = CAST(((Current_Date - Delivery_Qtr)/ 7)as INT)
)with data no primary index on commit preserve rows;

select sum(Total_Booked_Implied) from temp2;