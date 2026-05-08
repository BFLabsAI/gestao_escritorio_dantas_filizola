-- Create rastreia_lead_kiro_event_types table
-- Stores event type configurations for booking system
CREATE TABLE rastreia_lead_kiro_event_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 30 CHECK (duration_minutes > 0 AND duration_minutes <= 480),
  buffer_minutes INTEGER NOT NULL DEFAULT 0 CHECK (buffer_minutes >= 0 AND buffer_minutes <= 120),
  color TEXT NOT NULL DEFAULT '#3B82F6',
  is_active BOOLEAN NOT NULL DEFAULT true,
  pre_booking_questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Create indexes for event_types
CREATE INDEX idx_rastreia_lead_kiro_event_types_org_id ON rastreia_lead_kiro_event_types(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_event_types_is_active ON rastreia_lead_kiro_event_types(is_active);

-- Create rastreia_lead_kiro_appointments table
-- Stores scheduled appointments
CREATE TABLE rastreia_lead_kiro_appointments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  event_type_id UUID NOT NULL REFERENCES rastreia_lead_kiro_event_types(id) ON DELETE RESTRICT,
  contact_id UUID NOT NULL REFERENCES rastreia_lead_kiro_contacts(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES rastreia_lead_kiro_users(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'confirmed', 'cancelled', 'completed', 'no_show')),
  external_calendar_id TEXT,
  pre_booking_answers JSONB NOT NULL DEFAULT '{}'::jsonb,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Constraint: end_time must be after start_time
  CONSTRAINT check_appointment_times CHECK (end_time > start_time)
);

-- Create indexes for appointments
CREATE INDEX idx_rastreia_lead_kiro_appointments_org_id ON rastreia_lead_kiro_appointments(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_appointments_event_type_id ON rastreia_lead_kiro_appointments(event_type_id);
CREATE INDEX idx_rastreia_lead_kiro_appointments_contact_id ON rastreia_lead_kiro_appointments(contact_id);
CREATE INDEX idx_rastreia_lead_kiro_appointments_user_id ON rastreia_lead_kiro_appointments(user_id);
CREATE INDEX idx_rastreia_lead_kiro_appointments_start_time ON rastreia_lead_kiro_appointments(start_time);
CREATE INDEX idx_rastreia_lead_kiro_appointments_status ON rastreia_lead_kiro_appointments(status);
-- Composite index for date range queries
CREATE INDEX idx_rastreia_lead_kiro_appointments_time_range ON rastreia_lead_kiro_appointments(user_id, start_time, end_time);

-- Create rastreia_lead_kiro_booking_links table
-- Stores public booking links for scheduling
CREATE TABLE rastreia_lead_kiro_booking_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID NOT NULL REFERENCES rastreia_lead_kiro_organizations(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  event_type_id UUID NOT NULL REFERENCES rastreia_lead_kiro_event_types(id) ON DELETE CASCADE,
  user_id UUID REFERENCES rastreia_lead_kiro_users(id) ON DELETE CASCADE,
  team_id UUID REFERENCES rastreia_lead_kiro_teams(id) ON DELETE CASCADE,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Constraint: slug must be unique globally
  CONSTRAINT unique_booking_link_slug UNIQUE (slug),
  -- Constraint: must have either user_id or team_id (or both null for org-wide)
  CONSTRAINT check_booking_link_assignment CHECK (
    (user_id IS NOT NULL AND team_id IS NULL) OR
    (user_id IS NULL AND team_id IS NOT NULL) OR
    (user_id IS NULL AND team_id IS NULL)
  )
);

-- Create indexes for booking_links
CREATE INDEX idx_rastreia_lead_kiro_booking_links_org_id ON rastreia_lead_kiro_booking_links(organization_id);
CREATE INDEX idx_rastreia_lead_kiro_booking_links_slug ON rastreia_lead_kiro_booking_links(slug);
CREATE INDEX idx_rastreia_lead_kiro_booking_links_event_type_id ON rastreia_lead_kiro_booking_links(event_type_id);
CREATE INDEX idx_rastreia_lead_kiro_booking_links_user_id ON rastreia_lead_kiro_booking_links(user_id);
CREATE INDEX idx_rastreia_lead_kiro_booking_links_team_id ON rastreia_lead_kiro_booking_links(team_id);
CREATE INDEX idx_rastreia_lead_kiro_booking_links_is_active ON rastreia_lead_kiro_booking_links(is_active);

-- Enable Row Level Security
ALTER TABLE rastreia_lead_kiro_event_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE rastreia_lead_kiro_booking_links ENABLE ROW LEVEL SECURITY;

-- RLS Policies for event_types
-- Organization isolation policy
CREATE POLICY rastreia_lead_kiro_event_types_org_isolation
  ON rastreia_lead_kiro_event_types
  FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
    )
  );

-- RLS Policies for appointments
-- Organization isolation for managers and super_admins (can see all appointments)
CREATE POLICY rastreia_lead_kiro_appointments_manager_access
  ON rastreia_lead_kiro_appointments
  FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
      AND role IN ('super_admin', 'manager')
    )
  );

-- Consultant access policy - only see their own appointments
CREATE POLICY rastreia_lead_kiro_appointments_consultant_access
  ON rastreia_lead_kiro_appointments
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
      AND role = 'consultant'
      AND organization_id = rastreia_lead_kiro_appointments.organization_id
      AND id = rastreia_lead_kiro_appointments.user_id
    )
  );

-- RLS Policies for booking_links
-- Organization isolation policy
CREATE POLICY rastreia_lead_kiro_booking_links_org_isolation
  ON rastreia_lead_kiro_booking_links
  FOR ALL
  USING (
    organization_id IN (
      SELECT organization_id 
      FROM rastreia_lead_kiro_users 
      WHERE id = auth.uid()
    )
  );

-- Public read access for booking links (for public booking pages)
CREATE POLICY rastreia_lead_kiro_booking_links_public_read
  ON rastreia_lead_kiro_booking_links
  FOR SELECT
  USING (is_active = true);

-- Triggers to update updated_at timestamp
CREATE TRIGGER update_rastreia_lead_kiro_event_types_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_event_types
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rastreia_lead_kiro_appointments_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_appointments
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rastreia_lead_kiro_booking_links_updated_at
  BEFORE UPDATE ON rastreia_lead_kiro_booking_links
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();;
