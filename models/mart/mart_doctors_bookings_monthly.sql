/* 
A doctor is engaged when they meet following criteria:
- create at least 5 doctor bookings weekly (only full weeks in a month),
- at least 1 doctor booking weekly (only full weeks in a month) is created in a Mobile App.

Doctor's engagement changes over time and is calculated on a basis of calendar month.

Metrics:
1. Number of engaged doctors with at least 3 bookings from unique patients monthly, also as a share of all engaged doctors

select
    booking_month
    , count(doctor_id) as nb_of_egnaged_doctors
    , count(case when nb_of_unique_patients >= 3 then doctor_id end) as nb_of_engaged_doctors_with_at_least_3_patients
from mart_doctors_bookings_monthly
where is_engaged

2. Percent of new engaged doctors that get 1 new patients from marketplace in the 1st month after becoming engaged

select
    first_month.first_engagement_month
    , count(first_month.doctor_id) as nb_of_new_engaged_doctors
    , count(next_month.doctor_id) as nb_of_new_engaged_doctors_with_1_new_patient
    , (nb_of_new_engaged_doctors_with_1_new_patient / nb_of_new_engaged_doctors) * 100 as percent
from mart_doctors_bookings_monthly as first_month
left join mart_doctors_bookings_monthly as next_month
    on first_month.doctor_id = next_month.doctor_id
    and first_month.booking_month = add_months(next_month.booking_month, -1)
    and nb_of_new_patients_from_markeplace = 1
where booking_month = first_engagement_month 
group by 1

3. Number of new engaged doctors that get 2 patient bookings from new and unique patients in the 1st month after becoming engaged.

select
    first_month.first_engagement_month
    , count(first_month.doctor_id) as nb_of_new_engaged_doctors
    , count(next_month.doctor_id) as nb_of_new_engaged_doctors_with_2_patient_bookings
from mart_doctors_bookings_monthly as first_month
left join mart_doctors_bookings_monthly as next_month
    on first_month.doctor_id = next_month.doctor_id
    and first_month.booking_month = add_months(next_month.booking_month, -1)
    and nb_of_new_patients_from_markeplace = 2
where booking_month = first_engagement_month 
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
        -- Finding first patient visit for each doctor (if not provided from source)
        , coalesce(
            row_number() over (
                partition by fact_bookings.patient_id, fact_bookings.doctor_id
                order by fact_bookings.booked_at
            ) = 1
            , false
        ) as is_first_patient_visit
    from {{ ref('dates') }}
    inner join {{ ref('dim_doctors') }}
        -- defining the range for each doctor from its creation date until six months from now
        on months.year_month >= date_trunc('month', dim_doctors.created_at::date)
    left join {{ ref('fact_bookings') }}
        on dates.date_day = fact_booking.created_at::date
        and dim_doctors.doctor_id = fact_booking.doctor_id
        -- considering only not cancelled bookings
        and cancelled_at is null
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

, defining_engaged_doctors as (
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

, engaged_doctors as (
    select
        doctor_id
        , booking_month
        , is_engaged
        , first_value(booking_month) over (
            partition by doctor_id order by booking_month asc
        ) as first_engagement_month
        , booking_month = first_engagement_month as is_first_engagement_month
    from defining_engaged_doctors
    where is_engaged

)

select
    bookings_prep.doctor_id
    , bookings_prep.booking_month
    , coalesce(engaged_doctors.is_engaged, false) as is_engaged
    , coalesce(engaged_doctors.is_first_engagement_month, false) as is_first_engagement_month
    , engaged_doctors.first_engagement_month
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
left join engaged_doctors
    on bookings_prep.doctor_id = weekly_doctor_bookings.doctor_id
    and bookings_prep.booking_month = weekly_doctor_bookings.booking_month
group by all