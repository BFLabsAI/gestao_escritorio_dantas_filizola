-- Step 3: Make id NOT NULL
ALTER TABLE users_itarget_api ALTER COLUMN id SET NOT NULL;

-- Step 4: Add unique constraint on id
ALTER TABLE users_itarget_api ADD CONSTRAINT users_itarget_api_id_key UNIQUE (id);;
