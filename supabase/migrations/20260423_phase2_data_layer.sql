-- Peptilog — Phase 2 data layer migration
-- Canonical idempotent migration for all 6 user-data tables.
-- All tables use RLS with owner-only policies (SPEC.md §7.2).
-- Safe to re-run: every DDL statement uses IF NOT EXISTS guards.
-- Do NOT store PIN or biometric data here (local-only per SPEC §2.3).

-- ============================================================
-- peptides
-- ============================================================
CREATE TABLE IF NOT EXISTS public.peptides (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name        TEXT        NOT NULL,
  color       TEXT        NOT NULL,
  unit        TEXT        NOT NULL DEFAULT 'mg',
  is_active   BOOLEAN     NOT NULL DEFAULT true,
  is_custom   BOOLEAN     NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.peptides ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'peptides' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.peptides FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_peptides_user_id
  ON public.peptides (user_id);

-- ============================================================
-- injection_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.injection_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_id  UUID        REFERENCES public.peptides(id) ON DELETE SET NULL,
  dose_mg     NUMERIC(8,4) NOT NULL,
  route       TEXT        NOT NULL CHECK (route IN ('SubQ', 'IM')),
  units       NUMERIC(8,4),
  notes       TEXT,
  logged_at   TIMESTAMPTZ NOT NULL,
  is_deleted  BOOLEAN     NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.injection_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'injection_logs' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.injection_logs FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_injection_logs_user_logged
  ON public.injection_logs (user_id, logged_at DESC);

-- ============================================================
-- weight_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.weight_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  weight_kg   NUMERIC(6,2) NOT NULL,
  date        TIMESTAMPTZ NOT NULL,
  is_deleted  BOOLEAN     NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.weight_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'weight_logs' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.weight_logs FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_weight_logs_user_date
  ON public.weight_logs (user_id, date DESC);

-- ============================================================
-- sleep_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sleep_logs (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  hours          NUMERIC(4,2) NOT NULL CHECK (hours > 0 AND hours <= 24),
  quality_rating SMALLINT    CHECK (quality_rating BETWEEN 1 AND 5),
  date           TIMESTAMPTZ NOT NULL,
  is_deleted     BOOLEAN     NOT NULL DEFAULT false,
  isar_id        BIGINT,
  synced_at      TIMESTAMPTZ,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.sleep_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'sleep_logs' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.sleep_logs FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_date
  ON public.sleep_logs (user_id, date DESC);

-- ============================================================
-- blood_pressure_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS public.blood_pressure_logs (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  systolic    INTEGER     NOT NULL CHECK (systolic BETWEEN 50 AND 300),
  diastolic   INTEGER     NOT NULL CHECK (diastolic BETWEEN 30 AND 200),
  pulse       INTEGER     CHECK (pulse BETWEEN 20 AND 300),
  measured_at TIMESTAMPTZ NOT NULL,
  is_deleted  BOOLEAN     NOT NULL DEFAULT false,
  isar_id     BIGINT,
  synced_at   TIMESTAMPTZ,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.blood_pressure_logs ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'blood_pressure_logs' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.blood_pressure_logs FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_bp_logs_user_measured
  ON public.blood_pressure_logs (user_id, measured_at DESC);

-- ============================================================
-- reminders
-- ============================================================
CREATE TABLE IF NOT EXISTS public.reminders (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_id   UUID        REFERENCES public.peptides(id) ON DELETE SET NULL,
  days_of_week TEXT        NOT NULL,   -- e.g. "Mon,Wed,Fri"
  time         TEXT        NOT NULL,   -- "HH:MM" 24-hour
  is_active    BOOLEAN     NOT NULL DEFAULT true,
  isar_id      BIGINT,
  synced_at    TIMESTAMPTZ,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'reminders' AND policyname = 'Users can only access own data'
  ) THEN
    CREATE POLICY "Users can only access own data"
      ON public.reminders FOR ALL
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_reminders_user_id
  ON public.reminders (user_id);

-- ============================================================
-- auto-update updated_at on every write
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
  FOREACH t IN ARRAY ARRAY[
    'peptides',
    'injection_logs',
    'weight_logs',
    'sleep_logs',
    'blood_pressure_logs',
    'reminders'
  ]
  LOOP
    EXECUTE format(
      'DROP TRIGGER IF EXISTS trg_%1$s_set_updated_at ON public.%1$s;
       CREATE TRIGGER trg_%1$s_set_updated_at
         BEFORE UPDATE ON public.%1$s
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();',
      t
    );
  END LOOP;
END;
$$;
