
-- Allow authenticated users to SELECT (list/view) files in imoveis_rogaciano
CREATE POLICY "Allow viewing imoveis_rogaciano" 
ON storage.objects 
FOR SELECT 
USING (bucket_id = 'imoveis_rogaciano');

-- Allow authenticated users to INSERT (upload) files to imoveis_rogaciano
CREATE POLICY "Allow uploading to imoveis_rogaciano" 
ON storage.objects 
FOR INSERT 
WITH CHECK (bucket_id = 'imoveis_rogaciano');

-- Allow authenticated users to UPDATE files in imoveis_rogaciano
CREATE POLICY "Allow updating imoveis_rogaciano" 
ON storage.objects 
FOR UPDATE 
USING (bucket_id = 'imoveis_rogaciano');

-- Allow authenticated users to DELETE files from imoveis_rogaciano
CREATE POLICY "Allow deleting from imoveis_rogaciano" 
ON storage.objects 
FOR DELETE 
USING (bucket_id = 'imoveis_rogaciano');
;
