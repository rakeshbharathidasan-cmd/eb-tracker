-- =====================================================================
-- EB Tracker — Supabase schema
-- Run this whole file once in Supabase → SQL Editor → New query → Run.
-- Then edit the two emails at the bottom and run that INSERT.
-- =====================================================================

create extension if not exists pgcrypto;

-- Who is allowed in (only these emails can read/write anything)
create table if not exists public.household_members (
  email text primary key
);
alter table public.household_members enable row level security;   -- no policies: clients can't read it

create or replace function public.is_member()
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.household_members
                 where lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;

-- Daily logs: one row per floor per day
create table if not exists public.readings (
  id              uuid primary key default gen_random_uuid(),
  floor           text not null check (floor in ('GF','FF')),
  reading_date    date not null,
  units           numeric(10,2) not null check (units >= 0),
  meter_reading   numeric(12,2),
  note            text,
  entered_by      uuid default auth.uid(),
  entered_by_name text,
  updated_by_name text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  unique (floor, reading_date)
);

-- Billing-cycle starting points (fresh EB reading, or mid-cycle takeover)
create table if not exists public.cycles (
  id              uuid primary key default gen_random_uuid(),
  group_id        text not null check (group_id in ('GF','FF','ALL')),
  start_date      date not null,                 -- date of the EB assessor reading that began the cycle
  opening_units   numeric(10,2) not null default 0,  -- units already used when tracking took over
  anchor_date     date not null,                 -- logs on/after this date are added on top
  anchor_readings jsonb not null default '{}'::jsonb, -- meter readings at the anchor, e.g. {"GF":12450}
  note            text,
  created_by      uuid default auth.uid(),
  created_by_name text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  check (anchor_date >= start_date)
);

-- Shared settings (tariff, billing mode, cycle length…) — single row
create table if not exists public.app_settings (
  id              int primary key default 1 check (id = 1),
  data            jsonb not null default '{}'::jsonb,
  updated_by_name text,
  updated_at      timestamptz not null default now()
);

-- keep updated_at fresh
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists trg_readings_touch on public.readings;
create trigger trg_readings_touch before update on public.readings for each row execute function public.touch_updated_at();
drop trigger if exists trg_cycles_touch on public.cycles;
create trigger trg_cycles_touch before update on public.cycles for each row execute function public.touch_updated_at();

-- Row-level security: household members only
alter table public.readings     enable row level security;
alter table public.cycles       enable row level security;
alter table public.app_settings enable row level security;

do $$
declare t text;
begin
  foreach t in array array['readings','cycles','app_settings'] loop
    execute format('drop policy if exists "members all" on public.%I', t);
    execute format('create policy "members all" on public.%I for all to authenticated using (public.is_member()) with check (public.is_member())', t);
  end loop;
end $$;

-- Live sync between both phones
alter table public.readings replica identity full;
alter table public.cycles   replica identity full;
do $$ begin
  begin alter publication supabase_realtime add table public.readings;     exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.cycles;       exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table public.app_settings; exception when duplicate_object then null; end;
end $$;

-- =====================================================================
-- EDIT THESE TWO EMAILS (the logins you and your wife will use), then run:
-- =====================================================================
insert into public.household_members (email) values
  ('you@example.com'),
  ('wife@example.com')
on conflict do nothing;
