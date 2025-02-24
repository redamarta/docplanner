select 
    id as doctor_d
    , firstname as first_name
    , lastname as last_name
    , phonenumber as phonen_number
    , profile_url
    , email
    , city
    , specializations --list
    , created_at
    , updated_at
    --, deactivated_at
from {{ source('staging_docplanner', 'doctors') }}