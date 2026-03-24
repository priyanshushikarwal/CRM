alter table public.applications
add column if not exists plant_through text,
add column if not exists connection_type text,
add column if not exists electricity_bill_load decimal(10,3);
