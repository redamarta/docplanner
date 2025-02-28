/* Metrics:
1. Number of engaged doctors with at least 3 bookings from unique patients monthly, also as a share of all engaged doctors
2. Percent of new engaged doctors that get 1 new patients from marketplace in the 1st month after becoming engaged
3. Number of new engaged doctors that get 2 patient bookings from new and unique patients in the 1st month after becoming engaged.
 */

select
    booking_month
    , count(case when is_engaged then doctor_id end) as nb_of_egnaged_doctors
    , count(case when is_engaged and nb_of_unique_patients >= 3 then doctor_id end) as nb_of_engaged_doctors_with_at_least_3_patients
    , count(case when first_engagement_month = booking_month then doctor_id end) as nb_of_new_engaged_doctors
    , count(case when first_engagement_month = booking_month and nb_of_new_patients_from_markeplace = 1 then doctor_id end) as nb_of_new_engaged_doctors_with_1_new_patient
    , (nb_of_new_engaged_doctors_with_1_new_patient / nb_of_new_engaged_doctors)*100 as percent_of_new_engaged_doctors_with_1_new_patient
    , count(case when first_engagement_month = booking_month and nb_of_new_patients = 2 then doctor_id end) as nb_of_new_engaged_doctors_with_2_new_patients
from from {{ ref('fact_doctors_engagment') }}
left join {{ ref('fact_doctors_engagment') }} as next_month
    on first_month.doctor_id = next_month.doctor_id
    and first_month.booking_month = add_months(next_month.booking_month, -1)
group by 1