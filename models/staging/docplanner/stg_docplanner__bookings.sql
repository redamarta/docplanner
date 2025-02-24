
select 
    id as booking_id
    , calendar_id
    , patient_id
    , doctor_id
    , created_at
    , booked_date
    , start_at
    , end_at
    , duration
    , service
    , status
    , source
    , canceled_at
from {{ source('staging_docplanner', 'bookings') }}