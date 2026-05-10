-- ========================================================================================
-- PAGEBOUND: COMPLETE MASTER SQL SCHEMA
-- Run this ENTIRE file in your Supabase SQL Editor.
-- It will wipe existing tables and cleanly recreate everything with the exact correct fields.
-- ========================================================================================

-- 1. DROP EXISTING TABLES TO CLEAN THE SLATE
DROP TABLE IF EXISTS public.battles CASCADE;
DROP TABLE IF EXISTS public.thread_replies CASCADE;
DROP TABLE IF EXISTS public.threads CASCADE;
DROP TABLE IF EXISTS public.club_members CASCADE;
DROP TABLE IF EXISTS public.clubs CASCADE;
DROP TABLE IF EXISTS public.xp_log CASCADE;
DROP TABLE IF EXISTS public.annual_goals CASCADE;
DROP TABLE IF EXISTS public.notes CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.reading_sessions CASCADE;
DROP TABLE IF EXISTS public.user_books CASCADE;
DROP TABLE IF EXISTS public.books CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ========================================================================================
-- 2. CREATE PUBLIC USERS TABLE & SYNC TRIGGER
-- Supabase keeps users in `auth.users` which we can't query. We must mirror it in `public`.
-- ========================================================================================
CREATE TABLE public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  xp INTEGER DEFAULT 0,
  level INTEGER DEFAULT 1,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users are viewable by everyone." ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile." ON public.users FOR UPDATE USING (auth.uid() = id);

-- Trigger function to copy new signups into public.users
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, full_name, avatar_url, username)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Attach trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- Sync any existing users from auth.users right now
INSERT INTO public.users (id, full_name, avatar_url, username)
SELECT 
  id, 
  raw_user_meta_data->>'full_name', 
  raw_user_meta_data->>'avatar_url', 
  COALESCE(raw_user_meta_data->>'username', split_part(email, '@', 1))
FROM auth.users
ON CONFLICT (id) DO NOTHING;

-- ========================================================================================
-- 3. CORE LIBRARY TABLES
-- ========================================================================================
CREATE TABLE public.books (
  id TEXT PRIMARY KEY,
  isbn_10 TEXT,
  isbn_13 TEXT,
  title TEXT NOT NULL,
  authors TEXT[] DEFAULT '{}',
  publisher TEXT,
  published_date TEXT,
  description TEXT,
  page_count INTEGER,
  categories TEXT[] DEFAULT '{}',
  thumbnail_url TEXT,
  language TEXT DEFAULT 'en',
  average_rating DOUBLE PRECISION
);

ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Books are viewable by everyone." ON public.books FOR SELECT USING (true);
CREATE POLICY "Users can insert books." ON public.books FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Users can update books." ON public.books FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE TABLE public.user_books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  status TEXT NOT NULL,
  current_page INTEGER DEFAULT 0,
  total_pages INTEGER,
  start_date DATE,
  finish_date DATE,
  is_public BOOLEAN DEFAULT true,
  shelf_position INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, book_id)
);

ALTER TABLE public.user_books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their own books." ON public.user_books FOR SELECT USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "Users can insert their own books." ON public.user_books FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own books." ON public.user_books FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own books." ON public.user_books FOR DELETE USING (auth.uid() = user_id);

-- ========================================================================================
-- 4. PROGRESS & REVIEWS & NOTES
-- ========================================================================================
CREATE TABLE public.reading_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  pages_read INTEGER NOT NULL,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users control own sessions." ON public.reading_sessions FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL,
  review_text TEXT,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, book_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews viewable by everyone." ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users control own reviews." ON public.reviews FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users control own notes." ON public.notes FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.annual_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  target_books INTEGER NOT NULL,
  books_finished INTEGER DEFAULT 0,
  UNIQUE(user_id, year)
);

ALTER TABLE public.annual_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users control own goals." ON public.annual_goals FOR ALL USING (auth.uid() = user_id);

-- ========================================================================================
-- 5. GAMIFICATION (XP Logs)
-- ========================================================================================
CREATE TABLE public.xp_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  xp_earned INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.xp_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users control own xp." ON public.xp_log FOR ALL USING (auth.uid() = user_id);

-- ========================================================================================
-- 6. COMMUNITY (Clubs, Threads, Battles)
-- ========================================================================================
CREATE TABLE public.clubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  member_count INTEGER DEFAULT 1,
  current_book_id TEXT REFERENCES public.books(id) ON DELETE SET NULL,
  owner_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
  is_public BOOLEAN DEFAULT true,
  invite_code TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Clubs are viewable by everyone." ON public.clubs FOR SELECT USING (true);
CREATE POLICY "Authenticated users can create clubs." ON public.clubs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "Owners can update clubs." ON public.clubs FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Owners can delete clubs." ON public.clubs FOR DELETE USING (auth.uid() = owner_id);

CREATE TABLE public.club_members (
  club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member',
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY(club_id, user_id)
);

ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members viewable by everyone." ON public.club_members FOR SELECT USING (true);
CREATE POLICY "Users control own membership." ON public.club_members FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id TEXT REFERENCES public.books(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  has_spoilers BOOLEAN DEFAULT false,
  reply_count INTEGER DEFAULT 0,
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Threads are viewable by everyone." ON public.threads FOR SELECT USING (true);
CREATE POLICY "Users can create threads." ON public.threads FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Users can delete own threads." ON public.threads FOR DELETE USING (auth.uid() = author_id);

CREATE TABLE public.thread_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  has_spoilers BOOLEAN DEFAULT false,
  parent_reply_id UUID REFERENCES public.thread_replies(id) ON DELETE CASCADE,
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.thread_replies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Replies viewable by everyone." ON public.thread_replies FOR SELECT USING (true);
CREATE POLICY "Users control own replies." ON public.thread_replies FOR ALL USING (auth.uid() = author_id);

CREATE TABLE public.battles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  opponent_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  target_pages INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  challenger_pages INTEGER DEFAULT 0,
  opponent_pages INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Battles are viewable by everyone." ON public.battles FOR SELECT USING (true);
CREATE POLICY "Users can create battles." ON public.battles FOR INSERT WITH CHECK (auth.uid() = challenger_id);
CREATE POLICY "Participants can update battles." ON public.battles FOR UPDATE USING (auth.uid() = challenger_id OR auth.uid() = opponent_id);

-- ========================================================================================
-- 8. RPC FUNCTIONS (GAMIFICATION & COUNTERS)
-- ========================================================================================

CREATE OR REPLACE FUNCTION public.increment_user_xp(user_id_param UUID, amount INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE public.users 
  SET xp = xp + amount
  WHERE id = user_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.increment_reply_count(thread_id_param UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.threads 
  SET reply_count = reply_count + 1
  WHERE id = thread_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ========================================================================================
-- 9. REFRESH SCHEMA CACHE
-- ========================================================================================
NOTIFY pgrst, 'reload schema';
