select 
    original_booking_id,
    booking_id
from {{ source('staging_docplanner', 'booking_change_log') }}