-- Migration: Create UTM Links Table
-- Description: Stores generated marketing links with UTM parameters.

CREATE TABLE IF NOT EXISTS utm_links_allblacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL, -- To identify the link internally
    original_url TEXT NOT NULL,
    utm_source TEXT,
    utm_medium TEXT,
    utm_campaign TEXT,
    utm_term TEXT,
    utm_content TEXT,
    final_url TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE utm_links_allblacks ENABLE ROW LEVEL SECURITY;

-- Allow Public Access (for Admin Dashboard without strict Auth for now)
CREATE POLICY "Public Full Access UTM Links"
ON utm_links_allblacks
FOR ALL
TO public
USING (true)
WITH CHECK (true);;
