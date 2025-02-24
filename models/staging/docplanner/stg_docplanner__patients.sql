
select 
    id as patient_id
    , firstname as first_name
    , lastname as last_name
    , datebirth as date_of_birth
    , gender
    , address
    , phonenumber as phonen_number
    , email
    , created_at
    , updated_at
from {{ source('staging_docplanner', 'patients') }}
