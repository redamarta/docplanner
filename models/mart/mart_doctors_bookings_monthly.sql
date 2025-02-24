/* 
A doctor is engaged when they meet following criteria:
- create at least 5 doctor bookings weekly (only full weeks in a month),
- at least 1 doctor booking weekly (only full weeks in a month) is created in a Mobile App.

Doctor's engagement changes over time and is calculated on a basis of calendar month.

Measures:
1. Number of engaged doctors with at least 3 bookings from unique patients monthly, also as a share of all engaged doctors,
2. Percent of new engaged doctors that get 1 new patients from marketplace in the 1st month after becoming engaged,
3. Number of new engaged doctors that get 2 patient bookings from new and unique patients in the 1st month after becoming engaged.
*/

with bookings_prep as (
    select
        dim_doctors.doctor_id
        , dates.year_month as booking_month
        , dates.week_of_year
        , dates.weekly_completion_in_month
        , fact_booking.booking_id
        , fact_booking.booked_by
        , fact_booking.patient_id
        -- not sure if I can this info from source
        , coalesce(
            row_number() over (
                partition by fact_bookings.patient_id, fact_bookings.doctor_id
                order by fact_bookings.booked_at
            ) = 1
            , false
        ) as is_first_patient_visit
    from {{ ref('dates') }}
    inner join {{ ref('dim_doctors') }}
        on months.year_month >= date_trunc('month', dim_doctors.created_at::date)
    left join {{ ref('fact_bookings') }}
        on dates.date_day = fact_booking.booked_at::date
        and dim_doctors.doctor_id = fact_booking.doctor_id
    group by all
)

, weekly_doctor_bookings as (
    select
        doctor_id
        , booking_month
        , week_of_year
        , weekly_completion_in_month
        , count(booking_id) as total_doctor_bookings
        , count(case when source = 'Mobile App' then booking_id end) as mobile_doctor_bookings
    from bookings_prep
    where booked_by = 'doctor'
    group by all
)

, engaged_doctors as (
    select
        doctor_id
        , booking_month
        /* The condition has to be met for all full weeks; if exists 0 then not engaged.
        The partial weeks are not considered. */
        , min(
            case
                when weekly_completion_in_month = 'full_week' then
                    case 
                        when total_doctor_bookings >= 5 and mobile_doctor_bookings >= 1
                            then 1
                        else 0
                    end
                else 1
            end
        ) as is_engaged
    from weekly_doctor_bookings
    group by all
)

, engaged_doctors_extended as (
    select
        doctor_id
        , booking_month
        , is_engaged
        , coalesce(
            is_engaged and booking_month = first_value(booking_month) over (
                    partition by doctor_id order by booking_month asc
                )
            , false
        ) as is_first_engagement_month
    from engaged_doctors
)

select
    bookings_prep.doctor_id
    , bookings_prep.booking_month
    , coalesce(engaged_doctors.is_engaged, false) as is_engaged
    , coalesce(engaged_doctors.is_first_engagement_month, false) as is_first_engagement_month
    , count(
        distinct 
        case
            when bookings_prep.is_first_patient_visit and bookings_prep.booked_by = 'patient'
                then bookings_prep.patient_id
        end
    ) as nb_of_new_patients_from_markeplace
    , count(distinct bookings_prep.patient_id) as nb_of_unique_patients
    , count(bookings_prep.booking_id) as total_bookings
    , count(case when bookings_prep.booked_by = 'patient' then bookings_prep.booking_id) as total_patient_bookings
    , sum(engaged_doctors.total_doctor_bookings) as total_doctor_bookings
from bookings_prep 
left join engaged_doctors_extended as engaged_doctors
    on bookings_prep.doctor_id = weekly_doctor_bookings.doctor_id
    and bookings_prep.booking_month = weekly_doctor_bookings.booking_month
group by all