create table if not exists public.installation_photos (
  id uuid primary key,
  installation_id uuid not null references public.installations(id) on delete cascade,
  application_id uuid not null references public.applications(id) on delete cascade,
  application_number text not null,
  photo_order integer not null,
  photo_type text not null,
  storage_path text not null,
  photo_url text not null,
  latitude double precision,
  longitude double precision,
  captured_by_user_id uuid references public.users(id) on delete set null,
  captured_by_user_name text,
  captured_at timestamptz,
  verification_status text not null default 'pending',
  verification_remarks text,
  verified_by_user_id uuid references public.users(id) on delete set null,
  verified_by_user_name text,
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (application_id, photo_order)
);

create index if not exists idx_installation_photos_application_id on public.installation_photos(application_id);
create index if not exists idx_installation_photos_installation_id on public.installation_photos(installation_id);
create index if not exists idx_installation_photos_status on public.installation_photos(verification_status);

alter table public.installation_photos enable row level security;

do $$
begin
  create policy "Authenticated users can view installation photos"
    on public.installation_photos
    for select
    to authenticated
    using (true);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create policy "Authenticated users can insert installation photos"
    on public.installation_photos
    for insert
    to authenticated
    with check (true);
exception
  when duplicate_object then null;
end $$;

do $$
begin
  create policy "Authenticated users can update installation photos"
    on public.installation_photos
    for update
    to authenticated
    using (true)
    with check (true);
exception
  when duplicate_object then null;
end $$;
