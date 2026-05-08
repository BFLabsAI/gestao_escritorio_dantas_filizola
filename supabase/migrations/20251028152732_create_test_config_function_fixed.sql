-- Create a simple test function to verify configuration access
CREATE OR REPLACE FUNCTION test_dispara_lead_config()
RETURNS TEXT AS $$
DECLARE
    api_url TEXT;
    api_key TEXT;
    openai_key TEXT;
    result TEXT := '';
BEGIN
    -- Test each configuration value
    SELECT get_dispara_lead_config('DISPARA_LEAD_PRODUCTION_EVOLUTION_API_URL') INTO api_url;
    SELECT get_dispara_lead_config('DISPARA_LEAD_PRODUCTION_EVOLUTION_API_KEY') INTO api_key;
    SELECT get_dispara_lead_config('DISPARA_LEAD_PRODUCTION_OPENAI_API_KEY') INTO openai_key;
    
    result := 'Configuration Test Results:' || E'\n';
    result := result || 'Evolution API URL: ' || COALESCE(api_url, 'NULL') || E'\n';
    result := result || 'Evolution API Key: ' || CASE WHEN api_key IS NOT NULL THEN LEFT(api_key, 10) || '...' ELSE 'NULL' END || E'\n';
    result := result || 'OpenAI API Key: ' || CASE WHEN openai_key IS NOT NULL THEN LEFT(openai_key, 10) || '...' ELSE 'NULL' END || E'\n';
    result := result || 'All configs accessible: ' || CASE 
        WHEN api_url IS NOT NULL AND api_key IS NOT NULL AND openai_key IS NOT NULL 
        THEN 'YES' 
        ELSE 'NO' 
    END;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Test the function
SELECT test_dispara_lead_config();;
