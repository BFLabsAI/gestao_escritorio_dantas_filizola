-- Migration: Allow Public Write Access for Admin Features (Temporary/No-Auth Mode)

-- 1. Contents Table Policies
DROP POLICY IF EXISTS "Public View Contents" ON contents_arsenal_allblacks;

CREATE POLICY "Public Full Access Contents"
ON contents_arsenal_allblacks
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- 2. Attachments Table Policies
DROP POLICY IF EXISTS "Public View Attachments" ON attachments_arsenal_allblacks;

CREATE POLICY "Public Full Access Attachments"
ON attachments_arsenal_allblacks
FOR ALL
TO public
USING (true)
WITH CHECK (true);

-- 3. Storage Policies (Materials Bucket)
-- Allow public uploads/deletes/updates to materials bucket
CREATE POLICY "Public Upload Materials"
ON storage.objects FOR INSERT TO public
WITH CHECK (bucket_id = 'materials_arsenal_allblacks');

CREATE POLICY "Public Update Materials"
ON storage.objects FOR UPDATE TO public
USING (bucket_id = 'materials_arsenal_allblacks');

CREATE POLICY "Public Delete Materials"
ON storage.objects FOR DELETE TO public
USING (bucket_id = 'materials_arsenal_allblacks');;
