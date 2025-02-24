{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

with merged_bookings as (
select
    booking_id
    , calendar_id
    , doctor_id
    , patient_id
    , booked_date
    , status
    -- Patients can do it from various sources: desktop or mobile website, mobile app, website widget, etc.
    , source
    , booked_by
from {{ ref('stg_docplanner__bookings') }}

union all 

select
    booking_id
    , calendar_id
    , doctor_id
    , patient_id
    , booked_date
    , status
    -- A doctor books a visit for a patient, for example coming from external sources (phone, different booking systems, etc.)
    , source
    , booked_by -- doctor, patient or secretary
from {{ ref('stg_external__bookings') }}
)

select * from merged_bookings
{% if is_incremental() %}
where updated_at > (select max(updated_at) from {{ this }})
{% endif %}