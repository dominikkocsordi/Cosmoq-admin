-- ============================================================
-- Cosmoq Admin – Supabase Setup
-- Einmal im Supabase SQL-Editor ausführen
-- ============================================================

-- 1. role-Spalte zur bestehenden profiles-Tabelle hinzufügen
--    (falls profiles noch nicht existiert, wird sie komplett angelegt)
create table if not exists public.profiles (
  id uuid references auth.users(id) on delete cascade primary key,
  email text,
  created_at timestamptz default now()
);

alter table public.profiles add column if not exists role text default null;

alter table public.profiles enable row level security;

-- 2. Profil wird automatisch bei Registrierung angelegt
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 3. RLS Policies für profiles
drop policy if exists "Admins can view profiles" on public.profiles;
create policy "Admins can view profiles" on public.profiles
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

-- 4. RLS für die tickets-Tabelle
alter table if exists public.tickets enable row level security;

drop policy if exists "Admins can do everything with tickets" on public.tickets;
create policy "Admins can do everything with tickets" on public.tickets
  for all using (
    (select role from public.profiles where id = auth.uid()) = 'admin'
  );

drop policy if exists "Users can view own tickets" on public.tickets;
create policy "Users can view own tickets" on public.tickets
  for select using (auth.uid() = user_id);

drop policy if exists "Users can insert tickets" on public.tickets;
create policy "Users can insert tickets" on public.tickets
  for insert with check (auth.uid() = user_id);

-- ============================================================
-- Ersten Admin vergeben (diese Zeile anpassen & ausführen):
-- UPDATE public.profiles SET role = 'admin' WHERE email = 'deine@email.de';
-- ============================================================
