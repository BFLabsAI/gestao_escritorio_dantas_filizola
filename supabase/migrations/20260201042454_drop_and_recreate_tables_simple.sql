-- Drop existing tables
DROP TABLE IF EXISTS subscriptions_itarget_api CASCADE;
DROP TABLE IF EXISTS events_itarget_api CASCADE;
DROP TABLE IF EXISTS users_itarget_api CASCADE;

-- ----------------------------------------------------------------------------
-- Table: users_itarget_api
-- ----------------------------------------------------------------------------
CREATE TABLE users_itarget_api (
    person_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    cpf TEXT UNIQUE,
    financial_status TEXT,
    access_token TEXT,
    token_expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Table: events_itarget_api
-- ----------------------------------------------------------------------------
CREATE TABLE events_itarget_api (
    activity_schedule_id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    amount DECIMAL(10,2),
    associated_amount DECIMAL(10,2),
    payment_plan_id INTEGER,
    vacancies INTEGER,
    start_date DATE,
    end_date DATE,
    images JSONB,
    cost_center_id INTEGER,
    member_status TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Table: subscriptions_itarget_api
-- ----------------------------------------------------------------------------
CREATE TABLE subscriptions_itarget_api (
    id INTEGER PRIMARY KEY,
    person_id INTEGER REFERENCES users_itarget_api(person_id),
    activity_schedule_id INTEGER REFERENCES events_itarget_api(activity_schedule_id),
    subscription_type TEXT NOT NULL,
    status INTEGER DEFAULT 1,
    account_receive_id INTEGER,
    account_receive_status INTEGER,
    amount DECIMAL(10,2),
    due_date DATE,
    cart_url TEXT,
    link_receipt TEXT,
    is_overdue BOOLEAN DEFAULT FALSE,
    is_cancelable BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Indexes
-- ----------------------------------------------------------------------------
CREATE INDEX idx_subscriptions_person ON subscriptions_itarget_api(person_id);
CREATE INDEX idx_subscriptions_status ON subscriptions_itarget_api(status);
CREATE INDEX idx_subscriptions_type ON subscriptions_itarget_api(subscription_type);
CREATE INDEX idx_events_category ON events_itarget_api(category);

-- ----------------------------------------------------------------------------
-- Row Level Security
-- ----------------------------------------------------------------------------
ALTER TABLE users_itarget_api ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions_itarget_api ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_itarget_api ENABLE ROW LEVEL SECURITY;

-- Service role (your middleware/agent) has full access
CREATE POLICY "service_full_users" ON users_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_full_subscriptions" ON subscriptions_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_full_events" ON events_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);;
