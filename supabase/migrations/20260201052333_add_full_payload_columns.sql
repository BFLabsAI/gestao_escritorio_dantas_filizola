-- Add full_payload column to store 100% of API response
ALTER TABLE events_itarget_api ADD COLUMN IF NOT EXISTS full_payload JSONB;
ALTER TABLE subscriptions_itarget_api ADD COLUMN IF NOT EXISTS full_payload JSONB;;
