 select  
    doctor_d
    , first_name
    , last_name
    , phonen_number
    , profile_url
    , email
    , city
    , specializations --list
    , created_at
    , updated_at
from {{ ref('stg_docplanner__doctors') }}