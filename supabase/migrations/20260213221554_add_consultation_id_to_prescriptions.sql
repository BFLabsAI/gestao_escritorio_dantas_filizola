-- Add consultation_id foreign key to prescriptions_evoluxhub
ALTER TABLE prescriptions_evoluxhub 
ADD COLUMN consultation_id UUID REFERENCES consultations_evoluxhub(id) ON DELETE SET NULL;

-- Create index for better query performance
CREATE INDEX idx_prescriptions_consultation_id ON prescriptions_evoluxhub(consultation_id);;
