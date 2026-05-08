-- Create function to find campaigns that should be completed but are stuck in active status
CREATE OR REPLACE FUNCTION find_stuck_campaigns()
RETURNS TABLE(
  id uuid,
  name text,
  status text,
  total_contacts integer,
  completed_sends bigint
) 
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT 
    c.id, 
    c.name, 
    c.status, 
    c.total_contacts,
    COUNT(CASE WHEN cs.status IN ('sent', 'failed') THEN 1 END) as completed_sends
  FROM campaigns_disparalead c
  LEFT JOIN campaign_sends_disparalead cs ON cs.campaign_id = c.id
  WHERE c.status = 'active'
  GROUP BY c.id, c.name, c.status, c.total_contacts
  HAVING COUNT(CASE WHEN cs.status IN ('sent', 'failed') THEN 1 END) >= c.total_contacts;
$$;;
