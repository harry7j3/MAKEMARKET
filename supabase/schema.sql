-- Run once in the Supabase SQL editor. All browser-accessible tables use RLS.
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'Maker',
  bio text not null default '',
  created_at timestamptz not null default now(),
  constraint profile_name_length check (char_length(display_name) between 1 and 48),
  constraint profile_bio_length check (char_length(bio) <= 300)
);

create schema if not exists private;

create or replace function private.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Maker'))
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function private.create_profile_for_new_user() from public, anon, authenticated;

create trigger on_auth_user_created_profile after insert on auth.users
for each row execute procedure private.create_profile_for_new_user();

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  description text not null,
  category text not null check (category in ('Art & manga','Games','Writing','Templates','Digital files','Music')),
  price_cents integer not null default 0 check (price_cents between 0 and 1000000),
  ai_use text not null default 'not-disclosed' check (ai_use in ('human-made','ai-assisted','ai-generated','not-disclosed')),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  created_at timestamptz not null default now(),
  constraint product_title_length check (char_length(title) between 3 and 90),
  constraint product_description_length check (char_length(description) between 10 and 2000)
);
create index if not exists products_public_created_idx on public.products(status, created_at desc);
create index if not exists products_seller_created_idx on public.products(seller_id, created_at desc);

create table if not exists public.favorites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, product_id)
);
create index if not exists favorites_product_idx on public.favorites(product_id);

create table if not exists public.content_reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  reason text not null check (reason in ('copied-work','unsafe','misleading','other')),
  details text not null default '',
  created_at timestamptz not null default now(),
  constraint report_details_length check (char_length(details) <= 1000)
);
create index if not exists content_reports_product_idx on public.content_reports(product_id);
create index if not exists content_reports_reporter_idx on public.content_reports(reporter_id);

alter table public.profiles enable row level security;
alter table public.products enable row level security;
alter table public.favorites enable row level security;
alter table public.content_reports enable row level security;

create policy "Profiles are visible" on public.profiles for select to anon, authenticated using (true);
create policy "Users edit their own profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "Approved products and your own drafts are visible" on public.products for select to anon, authenticated using (status = 'approved' or (select auth.uid()) = seller_id);
create policy "Signed-in users submit their own pending listings" on public.products for insert to authenticated with check ((select auth.uid()) = seller_id and status = 'pending');
create policy "Sellers edit their pending listings" on public.products for update to authenticated using ((select auth.uid()) = seller_id and status = 'pending') with check ((select auth.uid()) = seller_id and status = 'pending');
create policy "Sellers delete their pending listings" on public.products for delete to authenticated using ((select auth.uid()) = seller_id and status = 'pending');

create policy "Users see their own favorites" on public.favorites for select to authenticated using ((select auth.uid()) = user_id);
create policy "Users save their own favorites" on public.favorites for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Users remove their own favorites" on public.favorites for delete to authenticated using ((select auth.uid()) = user_id);

create policy "Signed-in users submit reports" on public.content_reports for insert to authenticated with check ((select auth.uid()) = reporter_id);

grant select on public.profiles, public.products to anon, authenticated;
grant update (display_name, bio) on public.profiles to authenticated;
grant insert, update, delete on public.products to authenticated;
grant select, insert, delete on public.favorites to authenticated;
grant insert on public.content_reports to authenticated;

