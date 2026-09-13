-- health_notes role bootstrap
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'health_notes') THEN
    CREATE ROLE health_notes LOGIN;
  END IF;
END
$$;

ALTER ROLE health_notes WITH REPLICATION;
