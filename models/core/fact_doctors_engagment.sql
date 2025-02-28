/* 
A doctor is engaged when they meet following criteria:
- create at least 5 doctor bookings weekly (only full weeks in a month),
- at least 1 doctor booking weekly (only full weeks in a month) is created in a Mobile App.

Doctor's engagement changes over time and is calculated on a basis of calendar month.
*/

with latest_booking_event as (
    select *
    from {{ ref('fact_bookings') }}
    qualify row_number() over (partition by original_booking_id order by created_at desc) = 1
)

, bookings_prep as (
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
                order by fact_bookings.created_at asc
            ) = 1
            , false
        ) as is_first_patient_visit
    from {{ ref('dates') }}
    inner join {{ ref('dim_doctors') }}
        -- defining the range for each doctor from its creation date until six months from now
        on months.year_month >= date_trunc('month', dim_doctors.created_at::date)
    left join latest_booking_event as fact_booking
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
    , count(
        distinct 
        case
            when bookings_prep.is_first_patient_visit then bookings_prep.patient_id
        end
    ) as nb_of_new_patients
    , count(distinct bookings_prep.patient_id) as nb_of_unique_patients
    , count(bookings_prep.booking_id) as total_bookings
    , count(case when bookings_prep.booked_by = 'patient' then bookings_prep.booking_id) as total_patient_bookings
    , sum(engaged_doctors.total_doctor_bookings) as total_doctor_bookings
from bookings_prep 
left join engaged_doctors
    on bookings_prep.doctor_id = weekly_doctor_bookings.doctor_id
    and bookings_prep.booking_month = weekly_doctor_bookings.booking_month
group by all