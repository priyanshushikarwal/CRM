CREATE TABLE IF NOT EXISTS public.installations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
    application_number TEXT NOT NULL,
    consumer_name TEXT NOT NULL,
    installation_date TIMESTAMPTZ,
    assigned_team TEXT,
    material_list TEXT[],
    completion_report TEXT,
    customer_signature_url TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.installations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can view installations" ON public.installations
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can manage installations" ON public.installations
    FOR ALL TO authenticated USING (true);

-- Indexes
CREATE INDEX idx_installations_application_id ON public.installations(application_id);
CREATE INDEX idx_installations_status ON public.installations(status);
