-- Migration: Update Arsenal Schema for Admin Features
-- Description: Adds 'text' to content_type_enum and 'tags' column to contents table.

-- 1. Add 'text' to content_type_enum
ALTER TYPE content_type_enum ADD VALUE IF NOT EXISTS 'text';

-- 2. Add 'tags' column to contents table
ALTER TABLE contents_arsenal_allblacks 
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}';

-- 3. Create index for tags (Gin index for array search performance)
CREATE INDEX IF NOT EXISTS idx_contents_tags ON contents_arsenal_allblacks USING GIN (tags);;
