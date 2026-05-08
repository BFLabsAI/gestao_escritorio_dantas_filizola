
-- Members profile table
CREATE TABLE members_proxpasso (
  id uuid PRIMARY KEY,
  phone text NOT NULL,
  nome text,
  sobrenome text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_members_proxpasso_phone ON members_proxpasso (phone);

-- Subscriptions (Kiwify integration)
CREATE TABLE subscriptions_proxpasso (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid NOT NULL REFERENCES members_proxpasso(id) ON DELETE CASCADE,
  kiwify_subscription_id text UNIQUE,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'past_due', 'cancelled', 'refunded', 'expired')),
  kiwify_payload jsonb,
  started_at timestamptz,
  expires_at timestamptz,
  cancelled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_subscriptions_proxpasso_member ON subscriptions_proxpasso (member_id);
CREATE INDEX idx_subscriptions_proxpasso_status ON subscriptions_proxpasso (status);

-- Clean days counter
CREATE TABLE clean_days_counter_proxpasso (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id uuid NOT NULL REFERENCES members_proxpasso(id) ON DELETE CASCADE,
  start_date date NOT NULL,
  is_active boolean NOT NULL DEFAULT true,
  reset_reason text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_clean_days_counter_proxpasso_active
  ON clean_days_counter_proxpasso (member_id)
  WHERE is_active = true;

-- Counter milestones
CREATE TABLE counter_milestones_proxpasso (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  counter_id uuid NOT NULL REFERENCES clean_days_counter_proxpasso(id) ON DELETE CASCADE,
  milestone_days int NOT NULL,
  notified_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (counter_id, milestone_days)
);

-- RLS
ALTER TABLE members_proxpasso ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions_proxpasso ENABLE ROW LEVEL SECURITY;
ALTER TABLE clean_days_counter_proxpasso ENABLE ROW LEVEL SECURITY;
ALTER TABLE counter_milestones_proxpasso ENABLE ROW LEVEL SECURITY;

CREATE POLICY "members_own_data" ON members_proxpasso
  FOR ALL USING (id = auth.uid());

CREATE POLICY "subscriptions_own_data" ON subscriptions_proxpasso
  FOR SELECT USING (member_id = auth.uid());

CREATE POLICY "counters_own_data" ON clean_days_counter_proxpasso
  FOR ALL USING (member_id = auth.uid());

CREATE POLICY "milestones_own_data" ON counter_milestones_proxpasso
  FOR SELECT USING (
    counter_id IN (
      SELECT id FROM clean_days_counter_proxpasso WHERE member_id = auth.uid()
    )
  );

-- Triggers
CREATE OR REPLACE FUNCTION update_updated_at_proxpasso()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at_members_proxpasso
  BEFORE UPDATE ON members_proxpasso
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_proxpasso();

CREATE TRIGGER set_updated_at_subscriptions_proxpasso
  BEFORE UPDATE ON subscriptions_proxpasso
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_proxpasso();
;
