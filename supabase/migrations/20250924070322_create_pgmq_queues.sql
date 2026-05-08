-- Create campaign message queue
SELECT pgmq.create('campaign_messages');

-- Create campaign scheduler queue  
SELECT pgmq.create('campaign_scheduler');;
