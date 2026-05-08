-- Create custom users table for development bypass
CREATE TABLE IF NOT EXISTS dispara_lead_production_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Create function for simple user signup (development only)
CREATE OR REPLACE FUNCTION dispara_lead_production_signup(
  email_param TEXT,
  password_param TEXT
) RETURNS JSON AS $$
DECLARE
  user_record UUID;
  result JSON;
BEGIN
  -- Insert new user
  INSERT INTO dispara_lead_production_users (email, password_hash)
  VALUES (email_param, password_param)
  RETURNING id INTO user_record;
  
  -- Return success result
  result := json_build_object(
    'success', true,
    'user_id', user_record,
    'email', email_param,
    'message', 'User created successfully'
  );
  
  RETURN result;
EXCEPTION
  WHEN unique_violation THEN
    RETURN json_build_object(
      'success', false,
      'error', 'Email already exists'
    );
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function for simple user verification (development only)
CREATE OR REPLACE FUNCTION dispara_lead_production_signin(
  email_param TEXT,
  password_param TEXT
) RETURNS JSON AS $$
DECLARE
  user_record RECORD;
  result JSON;
BEGIN
  -- Find user by email
  SELECT id, email, is_active INTO user_record
  FROM dispara_lead_production_users
  WHERE email = email_param AND is_active = true;
  
  IF NOT FOUND THEN
    RETURN json_build_object(
      'success', false,
      'error', 'User not found'
    );
  END IF;
  
  -- For development, we'll accept any password (remove in production)
  -- In production, you should hash and verify the password properly
  result := json_build_object(
    'success', true,
    'user_id', user_record.id,
    'email', user_record.email,
    'message', 'Login successful'
  );
  
  RETURN result;
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', false,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION dispara_lead_production_signup TO authenticated, anon;
GRANT EXECUTE ON FUNCTION dispara_lead_production_signin TO authenticated, anon;
GRANT SELECT ON dispara_lead_production_users TO authenticated, anon;;
