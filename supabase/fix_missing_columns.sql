-- Run this script in the Supabase SQL Editor to add the missing columns

-- Fix clubs table
ALTER TABLE public.clubs
ADD COLUMN IF NOT EXISTS owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS invite_code TEXT;

-- Fix club_members table
ALTER TABLE public.club_members
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'member';

-- Fix threads table (rename user_id to author_id if it exists)
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='threads' AND column_name='user_id') THEN
    ALTER TABLE public.threads RENAME COLUMN user_id TO author_id;
  END IF;
END $$;

ALTER TABLE public.threads
ADD COLUMN IF NOT EXISTS has_spoilers BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS reply_count INTEGER DEFAULT 0;

-- Fix thread_replies table (rename user_id to author_id if it exists)
DO $$
BEGIN
  IF EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name='thread_replies' AND column_name='user_id') THEN
    ALTER TABLE public.thread_replies RENAME COLUMN user_id TO author_id;
  END IF;
END $$;

ALTER TABLE public.thread_replies
ADD COLUMN IF NOT EXISTS has_spoilers BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS parent_reply_id UUID;

-- Refresh schema cache so PostgREST instantly picks up the new columns
NOTIFY pgrst, 'reload schema';
