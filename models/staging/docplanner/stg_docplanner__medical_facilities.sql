select 
    id as medical_facility_id
    , name
    , type
    , created_at
    , updated_at
    , addresses -- list of clinics, 
    /* online_only - with this parameter in url, query results will return additional parameter 
    indicating if an address is dedicated to video consultations */
from {{ source('staging_docplanner', 'medical_facilities') }}