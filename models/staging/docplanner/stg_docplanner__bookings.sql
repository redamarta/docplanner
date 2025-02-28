
select 
    id as booking_id
    , calendar_id
    , patient_id
    , doctor_id
    , created_at
    , start_at
    , end_at
    , duration
    , service
    , source
    , canceled_at
from {{ source('staging_docplanner', 'bookings') }}