select 
    patient_id
    , first_name
    , last_name
    , date_of_birth
    , country_code
    , address
    , phonen_number
    , email
    , created_at
    , updated_at
from {{ ref('stg_docplanner__patients') }}