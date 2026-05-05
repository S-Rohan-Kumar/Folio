-- RUN THIS IN YOUR SUPABASE SQL EDITOR --

-- 1. Create a trigger function to automatically update club member counts
CREATE OR REPLACE FUNCTION update_club_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.clubs SET member_count = member_count + 1 WHERE id = NEW.club_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.clubs SET member_count = GREATEST(1, member_count - 1) WHERE id = OLD.club_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Attach the trigger to the club_members table
DROP TRIGGER IF EXISTS on_club_member_change ON public.club_members;
CREATE TRIGGER on_club_member_change
AFTER INSERT OR DELETE ON public.club_members
FOR EACH ROW EXECUTE FUNCTION update_club_member_count();
