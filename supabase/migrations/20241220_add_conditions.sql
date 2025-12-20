-- Migration: Add conditions and condition_entries tables
-- Date: 2024-12-20

-- Create conditions table
CREATE TABLE IF NOT EXISTS public.conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    condition_status TEXT NOT NULL DEFAULT 'active' CHECK (condition_status IN ('active', 'resolved')),
    color_value INTEGER NOT NULL DEFAULT 15033203, -- 0xFFE57373
    icon_code_point INTEGER NOT NULL DEFAULT 62318, -- 0xf36e (bandage)
    notes TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create condition_entries table
CREATE TABLE IF NOT EXISTS public.condition_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    condition_id UUID NOT NULL REFERENCES public.conditions(id) ON DELETE CASCADE,
    entry_date TIMESTAMPTZ NOT NULL,
    severity INTEGER NOT NULL CHECK (severity >= 1 AND severity <= 10),
    phase TEXT NOT NULL DEFAULT 'onset' CHECK (phase IN ('onset', 'worsening', 'peak', 'improving')),
    notes TEXT NOT NULL DEFAULT '',
    linked_check_in_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for conditions
CREATE INDEX IF NOT EXISTS idx_conditions_user_id ON public.conditions(user_id);
CREATE INDEX IF NOT EXISTS idx_conditions_status ON public.conditions(condition_status);
CREATE INDEX IF NOT EXISTS idx_conditions_start_date ON public.conditions(start_date);

-- Create indexes for condition_entries
CREATE INDEX IF NOT EXISTS idx_condition_entries_condition_id ON public.condition_entries(condition_id);
CREATE INDEX IF NOT EXISTS idx_condition_entries_entry_date ON public.condition_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_condition_entries_linked_check_in ON public.condition_entries(linked_check_in_id);

-- Enable Row Level Security
ALTER TABLE public.conditions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.condition_entries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conditions table
CREATE POLICY "Users can view their own conditions"
    ON public.conditions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own conditions"
    ON public.conditions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conditions"
    ON public.conditions FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conditions"
    ON public.conditions FOR DELETE
    USING (auth.uid() = user_id);

-- RLS Policies for condition_entries table
CREATE POLICY "Users can view entries for their conditions"
    ON public.condition_entries FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM public.conditions
        WHERE conditions.id = condition_entries.condition_id
        AND conditions.user_id = auth.uid()
    ));

CREATE POLICY "Users can insert entries for their conditions"
    ON public.condition_entries FOR INSERT
    WITH CHECK (EXISTS (
        SELECT 1 FROM public.conditions
        WHERE conditions.id = condition_entries.condition_id
        AND conditions.user_id = auth.uid()
    ));

CREATE POLICY "Users can update entries for their conditions"
    ON public.condition_entries FOR UPDATE
    USING (EXISTS (
        SELECT 1 FROM public.conditions
        WHERE conditions.id = condition_entries.condition_id
        AND conditions.user_id = auth.uid()
    ));

CREATE POLICY "Users can delete entries for their conditions"
    ON public.condition_entries FOR DELETE
    USING (EXISTS (
        SELECT 1 FROM public.conditions
        WHERE conditions.id = condition_entries.condition_id
        AND conditions.user_id = auth.uid()
    ));

-- Create updated_at trigger function if it doesn't exist
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
DROP TRIGGER IF EXISTS set_conditions_updated_at ON public.conditions;
CREATE TRIGGER set_conditions_updated_at
    BEFORE UPDATE ON public.conditions
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_condition_entries_updated_at ON public.condition_entries;
CREATE TRIGGER set_condition_entries_updated_at
    BEFORE UPDATE ON public.condition_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

