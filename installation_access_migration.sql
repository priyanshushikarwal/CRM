alter table if exists users
add column if not exists installation_access boolean default false;

update users
set installation_access = true
where role in ('admin', 'factory')
  and installation_access is distinct from true;
