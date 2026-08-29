CREATE TABLE IF NOT EXISTS public.medication_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    medication_name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'mg',
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    steps JSONB NOT NULL DEFAULT '[]'::jsonb,
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_medication_schedules_user_id
    ON public.medication_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_schedules_start_date
    ON public.medication_schedules(start_date);

ALTER TABLE public.medication_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own medication schedules"
    ON public.medication_schedules FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own medication schedules"
    ON public.medication_schedules FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own medication schedules"
    ON public.medication_schedules FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own medication schedules"
    ON public.medication_schedules FOR DELETE
    USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_medication_schedules_updated_at
    ON public.medication_schedules;
CREATE TRIGGER set_medication_schedules_updated_at
    BEFORE UPDATE ON public.medication_schedules
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
