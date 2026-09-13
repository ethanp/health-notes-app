-- Flutter Color.value is an unsigned 32-bit ARGB int (can exceed INTEGER).
ALTER TABLE conditions
    ALTER COLUMN color_value TYPE BIGINT;

ALTER TABLE check_in_metrics
    ALTER COLUMN color_value TYPE BIGINT;
