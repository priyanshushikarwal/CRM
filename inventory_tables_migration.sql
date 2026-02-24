-- ============================================================
-- SOLAR INVENTORY TABLES
-- Run this SQL in your Supabase SQL Editor
-- ============================================================

-- 1. Solar Inventory Items Table
CREATE TABLE IF NOT EXISTS solar_inventory (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    panel_model TEXT NOT NULL,
    capacity_kw NUMERIC(8,2) NOT NULL,
    total_quantity INTEGER NOT NULL DEFAULT 0,
    used_quantity INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Solar Inventory Assignments Table
-- Tracks which solar panels are assigned to which applications
CREATE TABLE IF NOT EXISTS solar_inventory_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    inventory_item_id UUID NOT NULL REFERENCES solar_inventory(id) ON DELETE CASCADE,
    application_id TEXT NOT NULL,
    application_number TEXT NOT NULL,
    consumer_name TEXT NOT NULL,
    quantity_assigned INTEGER NOT NULL DEFAULT 1,
    assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    notes TEXT
);

-- 3. Enable Row Level Security
ALTER TABLE solar_inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE solar_inventory_assignments ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies - Allow all authenticated users to read
CREATE POLICY "Allow authenticated users to read inventory"
    ON solar_inventory FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated users to read assignments"
    ON solar_inventory_assignments FOR SELECT
    TO authenticated
    USING (true);

-- 5. RLS Policies - Allow all authenticated users to insert
CREATE POLICY "Allow authenticated users to insert inventory"
    ON solar_inventory FOR INSERT
    TO authenticated
    WITH CHECK (true);

CREATE POLICY "Allow authenticated users to insert assignments"
    ON solar_inventory_assignments FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- 6. RLS Policies - Allow authenticated users to update
CREATE POLICY "Allow authenticated users to update inventory"
    ON solar_inventory FOR UPDATE
    TO authenticated
    USING (true);

-- 7. RLS Policies - Allow authenticated users to delete
CREATE POLICY "Allow authenticated users to delete inventory"
    ON solar_inventory FOR DELETE
    TO authenticated
    USING (true);

CREATE POLICY "Allow authenticated users to delete assignments"
    ON solar_inventory_assignments FOR DELETE
    TO authenticated
    USING (true);

-- 8. Sample Data (Optional - remove if not needed)
-- INSERT INTO solar_inventory (company_name, panel_model, capacity_kw, total_quantity, used_quantity, description)
-- VALUES 
--     ('Adani Solar', 'ADANI-540M BiHiKu5', 3.0, 50, 0, 'Mono PERC bifacial panels'),
--     ('Tata Power Solar', 'TP500M72BH', 2.0, 30, 0, 'Standard residential panels'),
--     ('Waaree Energies', 'WE-400', 1.0, 100, 0, 'Economy series panels');

-- ============================================================
-- DONE! Copy and run this in Supabase SQL Editor
-- Go to: https://supabase.com > Your Project > SQL Editor
-- ============================================================
