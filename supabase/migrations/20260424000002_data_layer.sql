-- Peptilog: data layer migration — Phase 2
-- Adds: peptides, sleep_logs, blood_pressure_logs, reminders tables
-- injection_logs and weight_entries already exist from migration 000001.

-- ============================================================
-- peptides table (user + preset cloud sync)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.peptides (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT NOT NULL,
  color       TEXT NOT NULL,
  unit        TEXT NOT NULL DEFAULT 'mg',
  is_active   BOOLEAN NOT NULL DEFAULT true,
  is_custom   BOOLEAN NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.peptides ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own peptides"
  ON public.peptides FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_peptides_user_id ON public.peptides (user_id);

-- ============================================================
-- sleep_logs table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sleep_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date        DATE NOT NULL,
  hours       NUMERIC(4,2) NOT NULL CHECK (hours > 0 AND hours <= 24),
  quality_rating SMALLINT CHECK (quality_rating BETWEEN 1 AND 5),
  is_deleted  BOOLEAN NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, date)
);

ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own sleep logs"
  ON public.sleep_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date ON public.sleep_logs (user_id, date DESC);

-- ============================================================
-- blood_pressure_logs table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.blood_pressure_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  measured_at TIMESTAMPTZ NOT NULL,
  systolic    SMALLINT NOT NULL CHECK (systolic BETWEEN 50 AND 300),
  diastolic   SMALLINT NOT NULL CHECK (diastolic BETWEEN 30 AND 200),
  pulse       SMALLINT CHECK (pulse BETWEEN 20 AND 300),
  is_deleted  BOOLEAN NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blood_pressure_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own blood pressure logs"
  ON public.blood_pressure_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_bp_logs_user_measured ON public.blood_pressure_logs (user_id, measured_at DESC);

-- ============================================================
-- reminders table
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reminders (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_id     UUID REFERENCES public.peptides(id) ON DELETE SET NULL,
  days_of_week   TEXT NOT NULL,    -- e.g. "Mon,Wed,Fri"
  time           TEXT NOT NULL,    -- "HH:MM" 24-hour
  is_active      BOOLEAN NOT NULL DEFAULT true,
  isar_id        BIGINT,
  synced_at      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD their own reminders"
  ON public.reminders FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders (user_id);

-- ============================================================
-- Helper: auto-update updated_at on row change
-- ============================================================
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DO $$
DECLARE
  t TEXT;
BEGIN
  FOREACH t IN ARRAY ARRAY['peptides','sleep_logs','blood_pressure_logs','reminders']
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%1$s_updated_at ON public.%1$s;
       CREATE TRIGGER trg_%1$s_updated_at
         BEFORE UPDATE ON public.%1$s
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t
    );
  END LOOP;
END;
$$;
