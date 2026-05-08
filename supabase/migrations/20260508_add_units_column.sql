-- PEP-88: Add missing units column to injection_logs
-- The Flutter InjectionLog model has a `units` field (syringe units from the
-- dosing calculator) that was defined in the canonical phase-2 migration but
-- was never present in the live table, causing PGRST204 on every sync write.
ALTER TABLE public.injection_logs
  ADD COLUMN IF NOT EXISTS units NUMERIC(8,4);
