/* Metrics:
1. Percent of all patient bookings coming from the Mobile App in relation to other sources
2. Patient rebooking rate, calculated as a percentage of patients who rebook to all patients
*/

select
    booking_month
    , count(*) as total_patients
    , sum(mobile_bookings) as mobile_bookings
    , sum(case when is_rebooking then 1 else 0 end) as rebooking_patients
    , (rebooking_patients/total_patients)*100 as rebooking_rate
    , sum(total_bookings - mobile_bookings) as other_bookings
    , (mobile_bookings/nullif(other_bookings, 0))*100 as percent_mobile_to_others
from {{ ref('fact_patients_engagment') }}
group by 1