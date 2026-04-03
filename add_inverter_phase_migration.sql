ALTER TABLE inverter_items
ADD COLUMN IF NOT EXISTS inverter_phase TEXT NOT NULL DEFAULT 'Single Phase';

ALTER TABLE inverter_items
DROP CONSTRAINT IF EXISTS inverter_items_inverter_phase_check;

ALTER TABLE inverter_items
ADD CONSTRAINT inverter_items_inverter_phase_check
CHECK (inverter_phase IN ('Single Phase', 'Three Phase'));
