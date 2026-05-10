-- RUN THIS IN SUPABASE SQL EDITOR to support the rpc call
CREATE OR REPLACE FUNCTION increment_user_xp(user_id_param UUID, amount INT)
RETURNS void AS $$
BEGIN
  UPDATE public.users 
  SET xp = xp + amount
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;