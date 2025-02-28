select 
    address_id
    , facility_id
    , address_id
    , doctor_id
    , name
    , post_code
    , street
    , only_online
from {{ source('staging_docplanner', 'addresses') }}