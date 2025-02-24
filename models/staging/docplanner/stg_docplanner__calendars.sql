--The calendar is a virtual mapping of real address and a doctor schedule
select 
    id as calendar_id
    , address_id -- the address of the clinic
    , doctor_id -- can be null
    , status -- enable and disable
    , slots -- start, end, service, duration
    , created_at
    , deleted_at
from {{ source('staging_docplanner', 'calendar') }}