-- Step 8: Drop foreign key constraints on person_id
ALTER TABLE events_itarget_api DROP CONSTRAINT IF EXISTS events_itarget_api_person_id_fkey;
ALTER TABLE subscriptions_itarget_api DROP CONSTRAINT IF EXISTS subscriptions_itarget_api_person_id_fkey;;
