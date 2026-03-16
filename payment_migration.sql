CREATE TABLE IF NOT EXISTS public.payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    payment_mode TEXT NOT NULL, -- cash, phonePe, bankTransfer
    payment_type TEXT NOT NULL, -- advance, partial, final_payment
    transaction_number TEXT,
    payment_date TIMESTAMPTZ NOT NULL,
    remarks TEXT,
    collected_by TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can view payments" ON public.payments
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert payments" ON public.payments
    FOR INSERT TO authenticated WITH CHECK (true);

-- Indexes
CREATE INDEX idx_payments_application_id ON public.payments(application_id);
CREATE INDEX idx_payments_date ON public.payments(payment_date);
