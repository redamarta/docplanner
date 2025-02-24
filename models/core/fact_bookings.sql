select
    booking_id
    , calendar_id
    , doctor_id
    , patient_id
    , booked_at
    , status
    /* Patients can do it from various sources: desktop or mobile website, mobile app, website widget, etc.
    A doctor books a visit for a patient, for example coming from external sources (phone, different booking systems, etc.)*/
    , source
    , booked_by -- doctor, patient or secretary
    , is_first_visit_with_doctor
from {{ ref('stg_docplanner__doctors') }}