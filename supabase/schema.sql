-- 5.1 users
CREATE TABLE public.users (
  id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username            TEXT UNIQUE NOT NULL,
  display_name        TEXT,
  avatar_url          TEXT,
  bio                 TEXT,
  personality_type    TEXT,           -- e.g. "The Night Owl"
  personality_badge   TEXT,           -- emoji or icon code
  reading_goal_year   INT DEFAULT EXTRACT(YEAR FROM NOW()),
  reading_goal_target INT DEFAULT 12,
  xp                  INT DEFAULT 0,
  level               INT DEFAULT 1,
  streak_current      INT DEFAULT 0,
  streak_longest      INT DEFAULT 0,
  last_read_date      DATE,
  gemini_api_key      TEXT,           -- encrypted at rest, user-provided
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_at          TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read all profiles" ON public.users FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- 5.2 books
CREATE TABLE public.books (
  id              TEXT PRIMARY KEY,   -- Google Books volumeId
  isbn_10         TEXT,
  isbn_13         TEXT,
  title           TEXT NOT NULL,
  authors         TEXT[],
  publisher       TEXT,
  published_date  TEXT,
  description     TEXT,
  page_count      INT,
  categories      TEXT[],
  thumbnail_url   TEXT,
  language        TEXT DEFAULT 'en',
  average_rating  FLOAT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can read books" ON public.books FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert books" ON public.books FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- 5.3 user_books
CREATE TYPE reading_status AS ENUM ('want_to_read', 'reading', 'finished', 'dnf', 'on_hold');

CREATE TABLE public.user_books (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  status          reading_status NOT NULL DEFAULT 'want_to_read',
  current_page    INT DEFAULT 0,
  total_pages     INT,                -- overrides book.page_count if user sets it
  start_date      DATE,
  finish_date     DATE,
  is_public       BOOLEAN DEFAULT true,
  shelf_position  INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

ALTER TABLE public.user_books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can read own books" ON public.user_books FOR SELECT USING (auth.uid() = user_id OR is_public = true);
CREATE POLICY "Users can insert own books" ON public.user_books FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own books" ON public.user_books FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own books" ON public.user_books FOR DELETE USING (auth.uid() = user_id);

-- 5.4 reading_sessions
CREATE TABLE public.reading_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  start_page      INT NOT NULL,
  end_page        INT NOT NULL,
  pages_read      INT GENERATED ALWAYS AS (end_page - start_page) STORED,
  duration_secs   INT NOT NULL,       -- total seconds of active reading
  session_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  notes           TEXT,               -- optional mid-session note
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.reading_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can access own sessions" ON public.reading_sessions FOR ALL USING (auth.uid() = user_id);

-- 5.5 annual_goals
CREATE TABLE public.annual_goals (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  year            INT NOT NULL,
  target_books    INT NOT NULL DEFAULT 12,
  books_finished  INT DEFAULT 0,      -- denormalized counter, updated via trigger
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, year)
);

ALTER TABLE public.annual_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage own goals" ON public.annual_goals FOR ALL USING (auth.uid() = user_id);

-- 5.6 reviews
CREATE TABLE public.reviews (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  rating          FLOAT CHECK (rating >= 0.5 AND rating <= 5.0),
  body            TEXT,
  is_public       BOOLEAN DEFAULT true,
  contains_spoilers BOOLEAN DEFAULT false,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, book_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public reviews are readable" ON public.reviews FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users manage own reviews" ON public.reviews FOR ALL USING (auth.uid() = user_id);

-- 5.7 book_notes
CREATE TABLE public.book_notes (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  note_type       TEXT CHECK (note_type IN ('note', 'quote', 'highlight')),
  content         TEXT NOT NULL,
  page_number     INT,
  chapter         TEXT,
  is_private      BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.book_notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own notes" ON public.book_notes FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Public notes visible" ON public.book_notes FOR SELECT USING (is_private = false OR auth.uid() = user_id);

-- 5.8 clubs
CREATE TABLE public.clubs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  description     TEXT,
  cover_url       TEXT,
  owner_id        UUID NOT NULL REFERENCES public.users(id),
  is_public       BOOLEAN DEFAULT true,
  invite_code     TEXT UNIQUE,        -- 8-char alphanumeric, null for public clubs
  current_book_id TEXT REFERENCES public.books(id),
  member_count    INT DEFAULT 1,      -- denormalized
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.clubs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public clubs are visible" ON public.clubs FOR SELECT USING (is_public = true OR id IN (
  SELECT club_id FROM public.club_members WHERE user_id = auth.uid()
));
CREATE POLICY "Owners can update clubs" ON public.clubs FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Authenticated users can create clubs" ON public.clubs FOR INSERT WITH CHECK (auth.uid() = owner_id);

-- 5.9 club_members
CREATE TABLE public.club_members (
  club_id         UUID NOT NULL REFERENCES public.clubs(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role            TEXT DEFAULT 'member' CHECK (role IN ('owner', 'moderator', 'member')),
  joined_at       TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (club_id, user_id)
);

ALTER TABLE public.club_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can view club roster" ON public.club_members FOR SELECT USING (
  club_id IN (SELECT club_id FROM public.club_members WHERE user_id = auth.uid())
);
CREATE POLICY "Users can join clubs" ON public.club_members FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can leave clubs" ON public.club_members FOR DELETE USING (auth.uid() = user_id);

-- 5.10 threads
CREATE TABLE public.threads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  club_id         UUID REFERENCES public.clubs(id),  -- null = book-wide public thread
  author_id       UUID NOT NULL REFERENCES public.users(id),
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  has_spoilers    BOOLEAN DEFAULT false,
  reply_count     INT DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.threads ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public threads readable" ON public.threads FOR SELECT USING (
  club_id IS NULL OR club_id IN (SELECT club_id FROM public.club_members WHERE user_id = auth.uid())
);
CREATE POLICY "Authors manage threads" ON public.threads FOR ALL USING (auth.uid() = author_id);
CREATE POLICY "Members create threads" ON public.threads FOR INSERT WITH CHECK (auth.uid() = author_id);

-- 5.11 thread_replies
CREATE TABLE public.thread_replies (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  thread_id       UUID NOT NULL REFERENCES public.threads(id) ON DELETE CASCADE,
  author_id       UUID NOT NULL REFERENCES public.users(id),
  body            TEXT NOT NULL,
  has_spoilers    BOOLEAN DEFAULT false,
  parent_reply_id UUID REFERENCES public.thread_replies(id),  -- for nested replies (1 level)
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.thread_replies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone in thread context can read replies" ON public.thread_replies FOR SELECT USING (
  thread_id IN (SELECT id FROM public.threads)  -- inherits thread visibility
);
CREATE POLICY "Authors manage replies" ON public.thread_replies FOR ALL USING (auth.uid() = author_id);
CREATE POLICY "Authenticated users can reply" ON public.thread_replies FOR INSERT WITH CHECK (auth.uid() = author_id);

-- 5.12 battles
CREATE TYPE battle_status AS ENUM ('pending', 'active', 'completed', 'cancelled');

CREATE TABLE public.battles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id   UUID NOT NULL REFERENCES public.users(id),
  rival_id        UUID NOT NULL REFERENCES public.users(id),
  book_id         TEXT NOT NULL REFERENCES public.books(id),
  status          battle_status DEFAULT 'pending',
  challenger_page INT DEFAULT 0,
  rival_page      INT DEFAULT 0,
  winner_id       UUID REFERENCES public.users(id),
  ends_at         TIMESTAMPTZ,        -- optional deadline
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

ALTER TABLE public.battles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Battle participants can view" ON public.battles FOR SELECT USING (
  auth.uid() = challenger_id OR auth.uid() = rival_id
);
CREATE POLICY "Challengers create battles" ON public.battles FOR INSERT WITH CHECK (auth.uid() = challenger_id);
CREATE POLICY "Participants update battles" ON public.battles FOR UPDATE USING (
  auth.uid() = challenger_id OR auth.uid() = rival_id
);

-- 5.13 social_follows
CREATE TABLE public.social_follows (
  follower_id     UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  following_id    UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE public.social_follows ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Anyone can see follow relationships" ON public.social_follows FOR SELECT USING (true);
CREATE POLICY "Users manage own follows" ON public.social_follows FOR ALL USING (auth.uid() = follower_id);

-- 5.14 xp_log
CREATE TABLE public.xp_log (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  action          TEXT NOT NULL,      -- e.g. 'session_logged', 'book_finished', 'battle_won'
  xp_earned       INT NOT NULL,
  badge_unlocked  TEXT,               -- badge key, if this action unlocked one
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.xp_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own xp log" ON public.xp_log FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System inserts xp log" ON public.xp_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 5.15 Database Triggers
-- Auto-update books_finished in annual_goals when a book is marked finished
CREATE OR REPLACE FUNCTION update_annual_goal_counter()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'finished' AND OLD.status != 'finished' THEN
    INSERT INTO public.annual_goals (user_id, year, books_finished)
    VALUES (NEW.user_id, EXTRACT(YEAR FROM NOW()), 1)
    ON CONFLICT (user_id, year) DO UPDATE
    SET books_finished = annual_goals.books_finished + 1;
  ELSIF OLD.status = 'finished' AND NEW.status != 'finished' THEN
    UPDATE public.annual_goals
    SET books_finished = GREATEST(0, books_finished - 1)
    WHERE user_id = NEW.user_id AND year = EXTRACT(YEAR FROM NOW());
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_book_status_change
AFTER UPDATE ON public.user_books
FOR EACH ROW EXECUTE FUNCTION update_annual_goal_counter();

-- Auto-update streak on reading session creation
CREATE OR REPLACE FUNCTION update_reading_streak()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users
  SET 
    last_read_date = CURRENT_DATE,
    streak_current = CASE
      WHEN last_read_date = CURRENT_DATE - INTERVAL '1 day' THEN streak_current + 1
      WHEN last_read_date = CURRENT_DATE THEN streak_current
      ELSE 1
    END,
    streak_longest = GREATEST(streak_longest, CASE
      WHEN last_read_date = CURRENT_DATE - INTERVAL '1 day' THEN streak_current + 1
      ELSE 1
    END)
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_reading_session_created
AFTER INSERT ON public.reading_sessions
FOR EACH ROW EXECUTE FUNCTION update_reading_streak();

-- 6.3 Post-Auth User Creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, username, display_name, avatar_url)
  VALUES (
    NEW.id,
    SPLIT_PART(NEW.email, '@', 1) || '_' || FLOOR(RANDOM() * 9999),
    COALESCE(NEW.raw_user_meta_data->>'full_name', SPLIT_PART(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Performance indexes
CREATE INDEX idx_user_books_user_status ON public.user_books(user_id, status);
CREATE INDEX idx_user_books_finish_date ON public.user_books(finish_date) WHERE finish_date IS NOT NULL;
CREATE INDEX idx_reading_sessions_user_date ON public.reading_sessions(user_id, session_date);
CREATE INDEX idx_threads_book ON public.threads(book_id);
CREATE INDEX idx_threads_club ON public.threads(club_id) WHERE club_id IS NOT NULL;
CREATE INDEX idx_thread_replies_thread ON public.thread_replies(thread_id);
CREATE INDEX idx_battles_participants ON public.battles(challenger_id, rival_id);
CREATE INDEX idx_battles_status ON public.battles(status) WHERE status = 'active';
CREATE INDEX idx_xp_log_user ON public.xp_log(user_id, created_at);
CREATE INDEX idx_social_follows_follower ON public.social_follows(follower_id);
CREATE INDEX idx_social_follows_following ON public.social_follows(following_id);
