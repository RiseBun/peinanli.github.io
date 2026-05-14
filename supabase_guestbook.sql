-- Supabase schema for the public anonymous guestbook.
-- Run this in Supabase SQL Editor, then copy the project URL and anon key
-- into guestbookConfig in index.html.

create extension if not exists pgcrypto;

create table if not exists public.guestbook_messages (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  created_at timestamptz not null default now(),
  constraint guestbook_messages_content_length check (
    char_length(trim(content)) between 1 and 800
  )
);

alter table public.guestbook_messages enable row level security;

drop policy if exists "Anyone can read guestbook messages"
  on public.guestbook_messages;

create policy "Anyone can read guestbook messages"
  on public.guestbook_messages
  for select
  to anon
  using (true);

drop policy if exists "Anyone can publish anonymous guestbook messages"
  on public.guestbook_messages;

create policy "Anyone can publish anonymous guestbook messages"
  on public.guestbook_messages
  for insert
  to anon
  with check (
    char_length(trim(content)) between 1 and 800
  );

create index if not exists guestbook_messages_created_at_idx
  on public.guestbook_messages (created_at desc);
