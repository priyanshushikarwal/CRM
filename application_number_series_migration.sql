with ordered_applications as (
  select
    id,
    (11010 + row_number() over (order by created_at asc, id asc))::text as new_application_number
  from public.applications
),
updated_applications as (
  update public.applications applications
  set application_number = ordered_applications.new_application_number
  from ordered_applications
  where applications.id = ordered_applications.id
  returning applications.id, applications.application_number
)
update public.installations installations
set application_number = updated_applications.application_number
from updated_applications
where installations.application_id = updated_applications.id;
