alter table public.payments enable row level security;

drop policy if exists "Authenticated users can update payments" on public.payments;
create policy "Authenticated users can update payments" on public.payments
for update to authenticated
using (true)
with check (true);

drop policy if exists "Authenticated users can delete payments" on public.payments;
create policy "Authenticated users can delete payments" on public.payments
for delete to authenticated
using (true);
