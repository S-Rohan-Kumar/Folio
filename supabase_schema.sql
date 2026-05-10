-- Run this ENTIRE script in the Supabase SQL Editor

-- ==========================================
-- 1. CORE TABLES (Books & Library)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.books (
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
DROP POLICY IF EXISTS "Books are viewable by everyone." ON public.books;
CREATE POLICY "Books are viewable by everyone." ON public.books FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert/update books." ON public.books;
CREATE POLICY "Users can insert/update books." ON public.books FOR ALL USING (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS public.user_books (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
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
DROP POLICY IF EXISTS "Users can view their own books." ON public.user_books;
CREATE POLICY "Users can view their own books." ON public.user_books FOR SELECT USING (auth.uid() = user_id OR is_public = true);
DROP POLICY IF EXISTS "Users can insert their own books." ON public.user_books;
CREATE POLICY "Users can insert their own books." ON public.user_books FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update their own books." ON public.user_books;
CREATE POLICY "Users can update their own books." ON public.user_books FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can delete their own books." ON public.user_books;
CREATE POLICY "Users can delete their own books." ON public.user_books FOR DELETE USING (auth.uid() = user_id);

-- ==========================================
-- 2. PROGRESS & REVIEWS & NOTES
-- ==========================================

CREATE TABLE IF NOT EXISTS public.reading_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  pages_read INTEGER NOT NULL,
  duration_minutes INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users control own sessions." ON public.reading_sessions;
CREATE POLICY "Users control own sessions." ON public.reading_sessions FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL,
  review_text TEXT,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(user_id, book_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reviews viewable by everyone." ON public.reviews;
CREATE POLICY "Reviews viewable by everyone." ON public.reviews FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users control own reviews." ON public.reviews;
CREATE POLICY "Users control own reviews." ON public.reviews FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users control own notes." ON public.notes;
CREATE POLICY "Users control own notes." ON public.notes FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.annual_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  year INTEGER NOT NULL,
  target_books INTEGER NOT NULL,
  books_finished INTEGER DEFAULT 0,
  UNIQUE(user_id, year)
);

ALTER TABLE public.annual_goals ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users control own goals." ON public.annual_goals;
CREATE POLICY "Users control own goals." ON public.annual_goals FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- 3. GAMIFICATION (XP Logs)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.xp_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  xp_earned INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.xp_log ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users control own xp." ON public.xp_log;
CREATE POLICY "Users control own xp." ON public.xp_log FOR ALL USING (auth.uid() = user_id);

-- ==========================================
-- 4. COMMUNITY (Clubs, Threads, Battles)
-- ==========================================

CREATE TABLE IF NOT EXISTS public.clubs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  cover_url TEXT,
  member_count INTEGER DEFAULT 1,
  current_book_id TEXT REFERENCES public.books(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Clubs are viewable by everyone." ON public.clubs;
CREATE POLICY "Clubs are viewable by everyone." ON public.clubs FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create clubs." ON public.clubs;
CREATE POLICY "Authenticated users can create clubs." ON public.clubs FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE TABLE IF NOT EXISTS public.club_members (
  club_id UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  PRIMARY KEY(club_id, user_id)
);

ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Members viewable by everyone." ON public.club_members;
CREATE POLICY "Members viewable by everyone." ON public.club_members FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users control own membership." ON public.club_members;
CREATE POLICY "Users control own membership." ON public.club_members FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.threads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  club_id UUID REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Threads are viewable by everyone." ON public.threads;
CREATE POLICY "Threads are viewable by everyone." ON public.threads FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can create threads." ON public.threads;
CREATE POLICY "Users can create threads." ON public.threads FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.thread_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  upvotes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.thread_replies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Replies viewable by everyone." ON public.thread_replies;
CREATE POLICY "Replies viewable by everyone." ON public.thread_replies FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users control own replies." ON public.thread_replies;
CREATE POLICY "Users control own replies." ON public.thread_replies FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS public.battles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  opponent_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  book_id TEXT NOT NULL REFERENCES public.books(id) ON DELETE CASCADE,
  target_pages INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'active',
  challenger_pages INTEGER DEFAULT 0,
  opponent_pages INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Battles are viewable by everyone." ON public.battles;
CREATE POLICY "Battles are viewable by everyone." ON public.battles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can create battles." ON public.battles;
CREATE POLICY "Users can create battles." ON public.battles FOR INSERT WITH CHECK (auth.uid() = challenger_id);
DROP POLICY IF EXISTS "Participants can update battles." ON public.battles;
CREATE POLICY "Participants can update battles." ON public.battles FOR UPDATE USING (auth.uid() = challenger_id OR auth.uid() = opponent_id);

-- ==========================================
-- 5. REFRESH SCHEMA CACHE
-- ==========================================
-- This completely flushes the PostgREST cache so the API instantly sees all new tables!
NOTIFY pgrst, 'reload schema';
