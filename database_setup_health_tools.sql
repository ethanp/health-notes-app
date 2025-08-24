-- Health Tools Database Setup
-- Run this in your Supabase SQL editor

-- Create health_tool_categories table
CREATE TABLE IF NOT EXISTS health_tool_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT DEFAULT '',
    color_hex TEXT DEFAULT '#007AFF',
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create health_tools table
CREATE TABLE IF NOT EXISTS health_tools (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category_id UUID REFERENCES health_tool_categories(id) ON DELETE CASCADE,
    sort_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_health_tool_categories_user_id ON health_tool_categories(user_id);
CREATE INDEX IF NOT EXISTS idx_health_tool_categories_sort_order ON health_tool_categories(sort_order);
CREATE INDEX IF NOT EXISTS idx_health_tools_user_id ON health_tools(user_id);
CREATE INDEX IF NOT EXISTS idx_health_tools_category_id ON health_tools(category_id);
CREATE INDEX IF NOT EXISTS idx_health_tools_sort_order ON health_tools(sort_order);

-- Enable Row Level Security (RLS)
ALTER TABLE health_tool_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE health_tools ENABLE ROW LEVEL SECURITY;

-- Create policies for health_tool_categories
CREATE POLICY "Users can view their own health tool categories" ON health_tool_categories
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health tool categories" ON health_tool_categories
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health tool categories" ON health_tool_categories
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own health tool categories" ON health_tool_categories
    FOR DELETE USING (auth.uid() = user_id);

-- Create policies for health_tools
CREATE POLICY "Users can view their own health tools" ON health_tools
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own health tools" ON health_tools
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own health tools" ON health_tools
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own health tools" ON health_tools
    FOR DELETE USING (auth.uid() = user_id);

-- Add triggers to automatically set user_id on insert
CREATE OR REPLACE FUNCTION set_health_tool_category_user_id()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION set_health_tool_user_id()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_health_tool_category_user_id_trigger
    BEFORE INSERT ON health_tool_categories
    FOR EACH ROW
    EXECUTE FUNCTION set_health_tool_category_user_id();

CREATE TRIGGER set_health_tool_user_id_trigger
    BEFORE INSERT ON health_tools
    FOR EACH ROW
    EXECUTE FUNCTION set_health_tool_user_id();

-- Insert some default categories (optional - you can customize these)
INSERT INTO health_tool_categories (name, description, icon_name, color_hex, sort_order) VALUES
    ('Allergies', 'Tools and procedures for managing allergy symptoms', 'allergies', '#FF9500', 1),
    ('Anxiety', 'Coping strategies and tools for anxiety management', 'anxiety', '#FF3B30', 2),
    ('Nausea', 'Remedies and techniques for nausea relief', 'nausea', '#34C759', 3),
    ('Cold & Flu', 'Tools for managing cold and flu symptoms', 'cold', '#5AC8FA', 4),
    ('Travel', 'General travel-related health tools', 'travel', '#AF52DE', 5),
    ('Car Travel', 'Specific tools for car travel comfort', 'car_travel', '#FF2D92', 6),
    ('Plane Travel', 'Tools for managing air travel issues', 'plane_travel', '#FFCC00', 7)
ON CONFLICT DO NOTHING;

-- Insert some example tools (optional - you can customize these)
INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Flonase',
    'Nasal spray for allergy relief. Use 1-2 sprays per nostril once daily.',
    c.id,
    1
FROM health_tool_categories c WHERE c.name = 'Allergies'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Albuterol Inhaler',
    'Rescue inhaler for breathing difficulties. Use as prescribed.',
    c.id,
    2
FROM health_tool_categories c WHERE c.name = 'Allergies'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Lorazepam',
    'Anti-anxiety medication. Take as prescribed by doctor.',
    c.id,
    1
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    '54321 Senses Exercise',
    'Grounding technique: Name 5 things you can see, 4 you can touch, 3 you can hear, 2 you can smell, 1 you can taste.',
    c.id,
    2
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Move the Shape Exercise',
    'Physical grounding exercise: Move your body in different shapes to reconnect with your physical self.',
    c.id,
    3
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Deep Breathing',
    'Take slow, deep breaths: inhale for 4 counts, hold for 4, exhale for 4.',
    c.id,
    4
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Ginger Tea',
    'Natural remedy for nausea. Steep fresh ginger in hot water for 10 minutes.',
    c.id,
    1
FROM health_tool_categories c WHERE c.name = 'Nausea'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Acupressure',
    'Press the P6 point (inner wrist, 3 finger widths from wrist crease) for 30 seconds.',
    c.id,
    2
FROM health_tool_categories c WHERE c.name = 'Nausea'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Yoga',
    'Gentle stretching and breathing exercises to reduce stress and improve well-being.',
    c.id,
    5
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Go for a Walk',
    'Light physical activity to clear your mind and improve mood.',
    c.id,
    6
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;

INSERT INTO health_tools (name, description, category_id, sort_order) 
SELECT 
    'Warm Shower',
    'Relaxing warm shower to soothe muscles and calm the mind.',
    c.id,
    7
FROM health_tool_categories c WHERE c.name = 'Anxiety'
ON CONFLICT DO NOTHING;
