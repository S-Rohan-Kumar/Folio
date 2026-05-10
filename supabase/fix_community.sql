CREATE OR REPLACE FUNCTION increment_reply_count(thread_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.threads 
  SET reply_count = reply_count + 1
  WHERE id = thread_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;