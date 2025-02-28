{{ config(
    materialized='incremental',
    unique_key='booking_id'
) }}

-- bookings from marketplace
select
    bookings_log.original_booking_id
    , .bookings.booking_id
    , .bookings.calendar_id
    , .bookings.doctor_id
    , .bookings.patient_id
    , .bookings.created_at
    , .bookings.status
    , .bookings.source
    , .bookings.booked_by
from {{ ref('stg_docplanner__bookings') }} as bookings
left join {{ ref('stg_docplanner__booking_change_log') }} as bookings_log
    on bookings.booking_id = bookings_log.booking_id
{% if is_incremental() %}
where not exists (
    select null
    from {{ this }}
    where bookings.booking_id = {{ this }}.booking_id
)
{% endif %}

union all 

-- booking from external source done by doctor or secretary
select
    booking_id
    , calendar_id
    , doctor_id
    , patient_id
    , created_at
    , status
    , source
    , booked_by
from {{ ref('stg_external__bookings') }} as bookings
{% if is_incremental() %}
where not exists (
    select null
    from {{ this }}
    where bookings.booking_id = {{ this }}.booking_id
)
{% endif %}