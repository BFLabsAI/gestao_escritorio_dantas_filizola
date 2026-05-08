-- Allow all operations on instancias_odonto_solutti table
CREATE POLICY "Allow all operations on instancias" ON "public"."instancias_odonto_solutti"
FOR ALL 
USING (true) 
WITH CHECK (true);;
