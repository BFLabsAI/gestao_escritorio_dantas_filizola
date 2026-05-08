-- Step 5: Add user_id column to events_itarget_api
ALTER TABLE events_itarget_api ADD COLUMN user_id TEXT;

-- Step 6: Add user_id column to subscriptions_itarget_api
ALTER TABLE subscriptions_itarget_api ADD COLUMN user_id TEXT;

-- Step 7: Fill user_id based on person_id (copy for existing records)
UPDATE events_itarget_api e 
SET user_id = u.id 
FROM users_itarget_api u 
WHERE e.person_id = u.person_id AND e.user_id IS NULL;

UPDATE subscriptions_itarget_api s 
SET user_id = u.id 
FROM users_itarget_api u 
WHERE s.person_id = u.person_id AND s.user_id IS NULL;;
