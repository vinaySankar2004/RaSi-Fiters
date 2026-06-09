-- Add admin_only_data_entry flag to programs.
-- When true, the program is read-only for everyone except program admins
-- (and global admins): no loggers or members may add, edit, or delete
-- workout or daily-health logs. Configurable only by global_admin / program admin.
-- Run this on existing databases that were created before the column was added to db-schema.sql.

ALTER TABLE programs
    ADD COLUMN IF NOT EXISTS admin_only_data_entry BOOLEAN NOT NULL DEFAULT false;
