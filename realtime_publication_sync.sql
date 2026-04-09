do $$
begin
  begin
    alter publication supabase_realtime add table public.users;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.applications;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.documents;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.payments;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.installations;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.inventory_invoices;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.panel_items;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.inverter_items;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.meter_items;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.inventory_allotments;
  exception when duplicate_object then null;
  end;
end $$;
