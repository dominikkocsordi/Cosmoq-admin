-- ============================================================
-- Cosmoq Admin – Supabase Setup
-- Einmal im Supabase SQL-Editor ausführen
-- ============================================================

-- 1. role-Spalte zur bestehenden profiles-Tabelle hinzufügen
alter table public.profiles add column if not exists role text default null;

-- 2. RLS aktivieren
alter table public.profiles enable row level security;
alter table public.bug_reports enable row level security;

-- 3. Policies für profiles
drop policy if exists "Admins can view all profiles" on public.profiles;
create policy "Admins can view all profiles" on public.profiles
  for select using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

drop policy if exists "Admins can update profiles" on public.profiles;
create policy "Admins can update profiles" on public.profiles
  for update using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

drop policy if exists "Users can view own profile" on public.profiles;
create policy "Users can view own profile" on public.profiles
  for select using (auth.uid() = id);

-- 4. Policies für bug_reports
drop policy if exists "Admins can do everything with bug_reports" on public.bug_reports;
create policy "Admins can do everything with bug_reports" on public.bug_reports
  for all using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

drop policy if exists "Users can view own bug_reports" on public.bug_reports;
create policy "Users can view own bug_reports" on public.bug_reports
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert bug_reports" on public.bug_reports;
create policy "Users can insert bug_reports" on public.bug_reports
  for insert with check (auth.uid() = user_id);

-- ============================================================
-- Ersten Admin vergeben (E-Mail anpassen):
-- UPDATE public.profiles SET role = 'admin' WHERE id = (
--   SELECT id FROM auth.users WHERE email = 'deine@email.de'
-- );
-- ============================================================
