-- ============================================================================
-- iTarget Middleware - Simple Database Schema
-- ============================================================================
-- Just the essentials: users, events, subscriptions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: users_itarget_api
-- ----------------------------------------------------------------------------
CREATE TABLE users_itarget_api (
    person_id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT,
    cpf TEXT UNIQUE,

    -- Financial status: D = In Debt, Q = Paid Up
    financial_status TEXT, -- 'D' or 'Q'

    -- For middleware API calls
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

    -- Category: ANUIDADE, CURSOS AO VIVO, CURSOS ON DEMAND, PRESENCIAL
    category TEXT,

    -- Pricing
    amount DECIMAL(10,2),
    associated_amount DECIMAL(10,2), -- Member price
    payment_plan_id INTEGER,

    -- Availability
    vacancies INTEGER,
    start_date DATE,
    end_date DATE,

    -- Images (JSON)
    images JSONB,

    -- Extra info
    cost_center_id INTEGER,
    member_status TEXT, -- "Quite" or "Não quite"

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Table: subscriptions_itarget_api
-- ----------------------------------------------------------------------------
CREATE TABLE subscriptions_itarget_api (
    id INTEGER PRIMARY KEY,
    person_id INTEGER REFERENCES users_itarget_api(person_id),
    activity_schedule_id INTEGER REFERENCES events_itarget_api(activity_schedule_id),

    -- Type: ANUIDADE or EVENTO
    subscription_type TEXT NOT NULL, -- 'ANUIDADE' | 'EVENTO'

    -- Status: 1 = Pending, 2 = Subscribed, 3 = Cancelled
    status INTEGER DEFAULT 1,

    -- Payment
    account_receive_id INTEGER,
    account_receive_status INTEGER, -- 1 = Open, 2 = Paid, 3 = Quit
    amount DECIMAL(10,2),
    due_date DATE,

    -- Links
    cart_url TEXT,
    link_receipt TEXT,

    -- Flags
    is_overdue BOOLEAN DEFAULT FALSE,
    is_cancelable BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------------------------------------------
-- Indexes (for performance)
-- ----------------------------------------------------------------------------
CREATE INDEX idx_subscriptions_person ON subscriptions_itarget_api(person_id);
CREATE INDEX idx_subscriptions_status ON subscriptions_itarget_api(status);
CREATE INDEX idx_subscriptions_type ON subscriptions_itarget_api(subscription_type);
CREATE INDEX idx_events_category ON events_itarget_api(category);

-- ----------------------------------------------------------------------------
-- Row Level Security (basic)
-- ----------------------------------------------------------------------------
ALTER TABLE users_itarget_api ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions_itarget_api ENABLE ROW LEVEL SECURITY;
ALTER TABLE events_itarget_api ENABLE ROW LEVEL SECURITY;

-- Service role (middleware) has full access
CREATE POLICY "service_full_users" ON users_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_full_subscriptions" ON subscriptions_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "service_full_events" ON events_itarget_api FOR ALL TO service_role USING (true) WITH CHECK (true);

-- Everyone can see events (catalog)
CREATE POLICY "anon_events" ON events_itarget_api FOR SELECT TO anon USING (true);;
