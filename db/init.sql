-- health_notes schema for PowerSync (TEXT ids = client UUIDs)
-- Product soft-delete is_deleted is kept; PowerSync owns upload/download.

CREATE TABLE IF NOT EXISTS health_notes (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date_time TEXT NOT NULL,
    symptoms_list TEXT NOT NULL,
    drug_doses TEXT NOT NULL,
    notes TEXT NOT NULL,
    applied_tools TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_health_notes_user_id ON health_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_health_notes_date_time ON health_notes(date_time);

CREATE TABLE IF NOT EXISTS check_ins (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    rating INTEGER NOT NULL,
    date_time TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_check_ins_user_id ON check_ins(user_id);
CREATE INDEX IF NOT EXISTS idx_check_ins_date_time ON check_ins(date_time);

CREATE TABLE IF NOT EXISTS user_profiles (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS check_in_metrics (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    color_value BIGINT NOT NULL,
    icon_code_point INTEGER NOT NULL,
    sort_order INTEGER NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_check_in_metrics_user_id ON check_in_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_check_in_metrics_sort_order ON check_in_metrics(sort_order);

CREATE TABLE IF NOT EXISTS conditions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    name TEXT NOT NULL,
    start_date TEXT NOT NULL,
    end_date TEXT,
    condition_status TEXT NOT NULL DEFAULT 'active',
    color_value BIGINT NOT NULL DEFAULT 4293467747,
    icon_code_point INTEGER NOT NULL DEFAULT 62318,
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_conditions_user_id ON conditions(user_id);
CREATE INDEX IF NOT EXISTS idx_conditions_status ON conditions(condition_status);

CREATE TABLE IF NOT EXISTS condition_entries (
    id TEXT PRIMARY KEY,
    condition_id TEXT NOT NULL REFERENCES conditions(id),
    entry_date TEXT NOT NULL,
    severity INTEGER NOT NULL,
    phase TEXT NOT NULL DEFAULT 'onset',
    notes TEXT NOT NULL DEFAULT '',
    linked_check_in_id TEXT NOT NULL,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_condition_entries_condition_id ON condition_entries(condition_id);
CREATE INDEX IF NOT EXISTS idx_condition_entries_entry_date ON condition_entries(entry_date);

CREATE TABLE IF NOT EXISTS medication_schedules (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    medication_name TEXT NOT NULL,
    unit TEXT NOT NULL DEFAULT 'mg',
    start_date TEXT NOT NULL,
    end_date TEXT,
    steps TEXT NOT NULL DEFAULT '[]',
    notes TEXT NOT NULL DEFAULT '',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_medication_schedules_user_id ON medication_schedules(user_id);
CREATE INDEX IF NOT EXISTS idx_medication_schedules_start_date ON medication_schedules(start_date);

CREATE TABLE IF NOT EXISTS health_tool_categories (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    icon_name TEXT NOT NULL DEFAULT '',
    color_hex TEXT NOT NULL DEFAULT '#007AFF',
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS health_tools (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    category_id TEXT NOT NULL REFERENCES health_tool_categories(id),
    sort_order INTEGER NOT NULL DEFAULT 0,
    is_active INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_health_tools_category_id ON health_tools(category_id);
