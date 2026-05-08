-- Create storage policies for CV bucket
-- Public can upload to CV bucket
CREATE POLICY "Public can upload CVs" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'curriculos' AND
        auth.role() = 'anon'
    );

-- Authenticated users can read CVs
CREATE POLICY "Admins can read CVs" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'curriculos' AND
        auth.role() = 'authenticated'
    );

-- Authenticated users can update CVs
CREATE POLICY "Admins can update CVs" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'curriculos' AND
        auth.role() = 'authenticated'
    );

-- Create storage policies for Portfolio bucket
-- Public can upload to portfolio bucket
CREATE POLICY "Public can upload portfolios" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'portfolios' AND
        auth.role() = 'anon'
    );

-- Authenticated users can read portfolios
CREATE POLICY "Admins can read portfolios" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'portfolios' AND
        auth.role() = 'authenticated'
    );

-- Authenticated users can update portfolios
CREATE POLICY "Admins can update portfolios" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'portfolios' AND
        auth.role() = 'authenticated'
    );;
