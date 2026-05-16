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

create table if not exists public.site_metrics (
  metric_key text primary key,
  metric_value bigint not null default 0,
  updated_at timestamptz not null default now()
);

insert into public.site_metrics (metric_key, metric_value)
values ('homepage_views', 0)
on conflict (metric_key) do nothing;

insert into public.site_metrics (metric_key, metric_value)
values ('homepage_stars', 0)
on conflict (metric_key) do nothing;

alter table public.site_metrics enable row level security;

drop policy if exists "Anyone can read site metrics"
  on public.site_metrics;

create policy "Anyone can read site metrics"
  on public.site_metrics
  for select
  to anon
  using (true);

create or replace function public.increment_site_view()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  new_value bigint;
begin
  insert into public.site_metrics (metric_key, metric_value, updated_at)
  values ('homepage_views', 1, now())
  on conflict (metric_key) do update
    set metric_value = public.site_metrics.metric_value + 1,
        updated_at = now()
  returning metric_value into new_value;

  return new_value;
end;
$$;

revoke all on function public.increment_site_view() from public;
grant execute on function public.increment_site_view() to anon;

create or replace function public.increment_site_star()
returns bigint
language plpgsql
security definer
set search_path = public
as $$
declare
  new_value bigint;
begin
  insert into public.site_metrics (metric_key, metric_value, updated_at)
  values ('homepage_stars', 1, now())
  on conflict (metric_key) do update
    set metric_value = public.site_metrics.metric_value + 1,
        updated_at = now()
  returning metric_value into new_value;

  return new_value;
end;
$$;

revoke all on function public.increment_site_star() from public;
grant execute on function public.increment_site_star() to anon;
