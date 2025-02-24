/* 
A patient's engagement can be understood as their willingness to book a visit again.
The patient is called engaged if they:
- book at least 2 bookings monthly in 2 consecutive months (“this” and the previous one),
- at least 1 booking is created in the Mobile App (during the month).

A patient's engagement also changes over time and is calculated on a basis of calendar month.

We speak about rebooking if a patient books a visit again max. 30 days after previous booking. 

Measures:
1. Percent of all patient bookings coming from the Mobile App in relation to other sources

select
    booking_month
    , sum(mobile_bookings) as mobile_bookings
    , sum(total_bookings - mobile_bookings) as other_bookings
    , (mobile_bookings/nullif(other_bookings, 0))*100 as percent_mobile_to_others
from mart_patients_bookings_monthly
group by 1
 
2. Patient rebooking rate, calculated as a percentage of patients who rebook to all patients

select
    booking_month
    , count(*) as total_patients
    , sum(case when is_rebooking then 1 else 0 end) as rebooking_patients
    , (rebooking_patients/total_patients)*100 as rebooking_rate
from mart_patients_bookings_monthly
group by 1
*/

with bookings_prep as (
    select
        dim_patients.patient_id
        , dates.year_month as booking_month
        , booking_id
        , source
        , lag(booked_at) over (partition by patient_id order by booked_at) as previous_booking_at
        , colaesce(datediff(day, booked_at, previous_booking_at) <= 30, false) as is_rebooking
    from {{ ref('dates') }}
    inner join {{ ref('dim_patients') }}
        on months.year_month >= date_trunc('month', dim_patients.created_at::date)
    left join {{ ref('fact_bookings') }}
        on dates.date_day = fact_booking.created_at::date
        and dim_doctors.doctor_id = fact_booking.doctor_id
        and booked_by = 'patient'
)

, grouped_bookings as (
    select
        dim_patients.patient_id
        , dates.year_month as booking_month
        , count(booking_id) as total_bookings
        , count(case when source = 'Mobile App' then booking_id end) as mobile_bookings
        , max(is_rebooking) as is_rebooking
    from bookings_prep
    group by all
)

select
    patient_id
    , booking_month
    , is_rebooking
    , total_bookings
    , mobile_bookings
    , coalesce(
        total_bookings >= 2 and lag(total_bookings) over (partition by patient_id order by booking_month asc) >= 2
            and mobile_bookings >= 1
        , false
    ) as is_enagaed
from grouped_bookings