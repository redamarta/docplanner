--The calendar is a virtual mapping of real address and a doctor schedule
select 
    id as calendar_id
    , address_id
    , doctor_id -- can be null
    , status -- enable and disable
    , slots --variant with information such start, end, service, duration
    , created_at
    , updated_at
from {{ source('staging_docplanner', 'calendars') }}