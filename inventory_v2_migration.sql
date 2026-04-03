-- ============================================================
-- ADVANCED SOLAR INVENTORY TABLES (v2)
-- Based on Solar Inventory Management Software Blueprint
-- ============================================================

-- 1. Inventory Invoices (Unified for Panels, Inverters, Meters)
CREATE TABLE IF NOT EXISTS inventory_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_number TEXT NOT NULL,
    invoice_date DATE NOT NULL,
    party_name TEXT NOT NULL, -- Supplier
    price NUMERIC(12,2),
    received_by TEXT, -- Employee name
    item_type TEXT NOT NULL CHECK (item_type IN ('panel', 'inverter', 'meter')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Solar Panels Items
CREATE TABLE IF NOT EXISTS panel_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES inventory_invoices(id) ON DELETE CASCADE,
    serial_number TEXT UNIQUE NOT NULL,
    brand TEXT NOT NULL,
    watt_capacity INTEGER NOT NULL, -- e.g., 540
    panel_type TEXT NOT NULL CHECK (panel_type IN ('DCR', 'NDCR')),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'allotted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Inverter Items
CREATE TABLE IF NOT EXISTS inverter_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES inventory_invoices(id) ON DELETE CASCADE,
    serial_number TEXT UNIQUE NOT NULL,
    brand TEXT NOT NULL,
    capacity_kw NUMERIC(8,2) NOT NULL,
    inverter_type TEXT NOT NULL CHECK (inverter_type IN ('On Grid', 'Hybrid', 'Off Grid')),
    inverter_phase TEXT NOT NULL DEFAULT 'Single Phase' CHECK (inverter_phase IN ('Single Phase', 'Three Phase')),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'allotted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. Meter Items
CREATE TABLE IF NOT EXISTS meter_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id UUID REFERENCES inventory_invoices(id) ON DELETE CASCADE,
    serial_number TEXT UNIQUE NOT NULL,
    brand TEXT NOT NULL,
    meter_category TEXT NOT NULL CHECK (meter_category IN ('Net Meter', 'Solar Meter')),
    meter_type TEXT NOT NULL CHECK (meter_type IN ('Normal', 'LTCT', 'HTCT')),
    meter_phase TEXT NOT NULL CHECK (meter_phase IN ('Single Phase', 'Three Phase')),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'allotted')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Inventory Allotments (Handover)
CREATE TABLE IF NOT EXISTS inventory_allotments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    item_id UUID NOT NULL, -- Generic ID, logic will handle link based on item_type
    item_type TEXT NOT NULL CHECK (item_type IN ('panel', 'inverter', 'meter')),
    customer_name TEXT NOT NULL,
    customer_address TEXT,
    customer_mobile TEXT,
    application_id UUID REFERENCES applications(id) ON DELETE SET NULL,
    handover_by TEXT, -- Employee name
    handover_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Enable Row Level Security
ALTER TABLE inventory_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE panel_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inverter_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE meter_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_allotments ENABLE ROW LEVEL SECURITY;

-- 7. Policies (Updated to allow both authenticated and anon for demo sessions)
DROP POLICY IF EXISTS "inventory_invoices_policy" ON inventory_invoices;
CREATE POLICY "inventory_invoices_policy" ON inventory_invoices FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "panel_items_policy" ON panel_items;
CREATE POLICY "panel_items_policy" ON panel_items FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "inverter_items_policy" ON inverter_items;
CREATE POLICY "inverter_items_policy" ON inverter_items FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "meter_items_policy" ON meter_items;
CREATE POLICY "meter_items_policy" ON meter_items FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "inventory_allotments_policy" ON inventory_allotments;
CREATE POLICY "inventory_allotments_policy" ON inventory_allotments FOR ALL TO authenticated, anon USING (true) WITH CHECK (true);
