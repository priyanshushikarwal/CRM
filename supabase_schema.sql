-- Supabase Schema for DoonInfra Solar Manager
-- Run this SQL in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    full_name TEXT,
    phone TEXT,
    role TEXT DEFAULT 'viewer' CHECK (role IN ('superadmin', 'admin', 'vendor', 'operator', 'viewer')),
    is_active BOOLEAN DEFAULT true,
    profile_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_login_at TIMESTAMPTZ
);

-- Applications table
CREATE TABLE IF NOT EXISTS public.applications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_number TEXT UNIQUE NOT NULL,
    user_id UUID REFERENCES public.users(id),
    
    -- Application Details
    state TEXT NOT NULL,
    discom_name TEXT NOT NULL,
    full_name TEXT NOT NULL,
    gender TEXT NOT NULL,
    address TEXT NOT NULL,
    pincode TEXT NOT NULL,
    consumer_account_number TEXT NOT NULL,
    mobile TEXT NOT NULL,
    email TEXT,
    district TEXT NOT NULL,
    application_submission_date DATE NOT NULL,
    sc_st_status TEXT,
    circle_name TEXT NOT NULL,
    division_name TEXT NOT NULL,
    subdivision_name TEXT NOT NULL,
    scheme_name TEXT DEFAULT 'PM Surya Ghar: Muft Bijli Yojana',
    
    -- Bank Details
    bank_name TEXT,
    ifsc_code TEXT,
    account_holder_name TEXT,
    account_number TEXT,
    bank_remarks TEXT,
    give_up_subsidy BOOLEAN DEFAULT false,
    
    -- Solar Rooftop Details
    sanctioned_load DECIMAL(10,3) NOT NULL,
    proposed_capacity DECIMAL(10,3) NOT NULL,
    latitude DECIMAL(17,8),
    longitude DECIMAL(17,8),
    category_name TEXT NOT NULL,
    existing_installed_capacity DECIMAL(10,3) DEFAULT 0,
    net_eligible_capacity DECIMAL(10,3) NOT NULL,
    vendor_name TEXT NOT NULL,
    
    -- Loan Details
    loan_status TEXT DEFAULT 'Not Applied',
    loan_application_number TEXT,
    sanction_date DATE,
    sanction_amount DECIMAL(12,2),
    processing_fees DECIMAL(12,2),
    
    -- Feasibility Details
    feasibility_date DATE,
    feasibility_status TEXT DEFAULT 'Pending',
    feasibility_person TEXT,
    approved_capacity DECIMAL(10,3),
    remarks TEXT,
    
    -- Subsidy Details
    subsidy_amount DECIMAL(12,2),
    
    -- Status Tracking
    current_status TEXT DEFAULT 'consumerRegistration',
    status_history JSONB DEFAULT '[]'::jsonb,
    
    -- Approval Workflow
    approval_status TEXT DEFAULT 'draft' CHECK (approval_status IN ('draft', 'pending', 'approved', 'rejected', 'changesRequested')),
    submitted_by UUID REFERENCES public.users(id),
    approved_by UUID REFERENCES public.users(id),
    approval_date TIMESTAMPTZ,
    approval_remarks TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Documents table
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_url TEXT,
    file_size INTEGER,
    uploaded_on TIMESTAMPTZ DEFAULT NOW(),
    uploaded_by TEXT,
    remarks TEXT
);

-- Status history table (optional, for detailed tracking)
CREATE TABLE IF NOT EXISTS public.status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    application_id UUID REFERENCES public.applications(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    stage_status TEXT NOT NULL,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    remarks TEXT,
    updated_by TEXT
);

-- Create indexes for better performance
CREATE INDEX idx_applications_user_id ON public.applications(user_id);
CREATE INDEX idx_applications_status ON public.applications(current_status);
CREATE INDEX idx_applications_state ON public.applications(state);
CREATE INDEX idx_applications_district ON public.applications(district);
CREATE INDEX idx_applications_date ON public.applications(application_submission_date);
CREATE INDEX idx_applications_number ON public.applications(application_number);
CREATE INDEX idx_documents_application ON public.documents(application_id);

-- RLS Policies (Row Level Security)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Users policies
-- Allow users to view their own profile
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

-- Allow admins to view all users
CREATE POLICY "Admins can view all users" ON public.users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Allow users to update their own profile
CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Allow admins to update any user
CREATE POLICY "Admins can update any user" ON public.users
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Allow users to insert their own profile
CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow admins to insert new users
CREATE POLICY "Admins can insert users" ON public.users
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );


-- Applications policies (allow all authenticated users for now)
CREATE POLICY "Authenticated users can view applications" ON public.applications
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert applications" ON public.applications
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can update applications" ON public.applications
    FOR UPDATE TO authenticated USING (true);

CREATE POLICY "Authenticated users can delete applications" ON public.applications
    FOR DELETE TO authenticated USING (true);

-- Documents policies
CREATE POLICY "Authenticated users can view documents" ON public.documents
    FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert documents" ON public.documents
    FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Authenticated users can delete documents" ON public.documents
    FOR DELETE TO authenticated USING (true);

-- Create a storage bucket for documents
INSERT INTO storage.buckets (id, name, public) 
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies
CREATE POLICY "Authenticated users can upload documents" ON storage.objects
    FOR INSERT TO authenticated WITH CHECK (bucket_id = 'documents');

CREATE POLICY "Anyone can view documents" ON storage.objects
    FOR SELECT USING (bucket_id = 'documents');

CREATE POLICY "Authenticated users can delete documents" ON storage.objects
    FOR DELETE TO authenticated USING (bucket_id = 'documents');

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger to auto-update updated_at
CREATE TRIGGER update_applications_updated_at
    BEFORE UPDATE ON public.applications
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Create a function to handle new user signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, created_at)
    VALUES (NEW.id, NEW.email, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-create user profile on signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- Sample data (optional - for testing)
-- INSERT INTO public.applications (
--     application_number, state, discom_name, full_name, gender, address, pincode,
--     consumer_account_number, mobile, district, application_submission_date,
--     circle_name, division_name, subdivision_name, sanctioned_load, proposed_capacity,
--     category_name, net_eligible_capacity, vendor_name, latitude, longitude
-- ) VALUES (
--     'NP-RJAJY25-9202813', 'Rajasthan', 'Ajmer Vidyut Vitran Nigam Ltd.', 'Santosh Devi',
--     'Female', 'Nulldhani Khani Kinangai Nathusar', '332712', '1201/1004774', '9099689974',
--     'Sikar', '2025-12-03', 'Sikar', 'OnM Shrimadhopur', 'AEN (O And M), Shrimadhopur',
--     0.500, 4.400, 'Residential', 3.000, 'DOON INFRAPOWER PROJECTS PVT. LTD.',
--     27.560533, 75.714012
-- );
