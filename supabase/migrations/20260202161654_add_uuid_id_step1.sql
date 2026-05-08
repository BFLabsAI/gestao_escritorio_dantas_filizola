-- Step 1: Add new id column (nullable for now)
ALTER TABLE users_itarget_api ADD COLUMN id TEXT;

-- Step 2: Fill existing records with UUIDs
UPDATE users_itarget_api SET id = gen_random_uuid() WHERE id IS NULL;;
