 select  
    doctor_d
    , first_name
    , last_name
    , phone_number
    , profile_url
    , email
    , city
    , specializations
    , created_at
    , updated_at
from {{ ref('stg_docplanner__doctors') }}