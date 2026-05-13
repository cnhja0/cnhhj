-- =====================================================================
-- CNHhj — Schema inicial (MVP)
-- Migration: 0001_initial_schema
--
-- Define todas as tabelas, tipos e triggers necessários para o MVP
-- (apps mobile do Instrutor e do Aluno). Estrutura derivada do Figma
-- e do Excalidraw em docs/design/.
--
-- O que está fora do MVP (será adicionado em migrations futuras):
--   • Pagamentos, comissão, split, plano VIP
--   • Autoescolas, clínicas, exames médicos/psicotécnicos
--   • Patrocínio / posicionamento pago
--   • Painel admin web
-- =====================================================================

-- ---------------------------------------------------------------------
-- Extensões
-- ---------------------------------------------------------------------
create extension if not exists "pgcrypto";   -- gen_random_uuid()
create extension if not exists "postgis";    -- localização (point/geography), usado em fase 2

-- ---------------------------------------------------------------------
-- Tipos enumerados
-- ---------------------------------------------------------------------
create type user_role         as enum ('instrutor', 'aluno');
create type gender            as enum ('masculino', 'feminino', 'nao_informar');
create type approval_status   as enum ('pending', 'approved', 'rejected');
create type vehicle_type      as enum ('carro', 'moto', 'ambos');
create type transmission      as enum ('automatico', 'manual', 'ambos');
create type vehicle_category  as enum ('A', 'B', 'AB', 'C', 'D', 'E');
create type booking_status    as enum ('pending', 'confirmed', 'cancelled', 'completed', 'no_show');
create type review_target     as enum ('instructor', 'student');

-- ---------------------------------------------------------------------
-- Função utilitária: atualizar updated_at automaticamente
-- ---------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- =====================================================================
-- TABELA: profiles
-- Dados de identidade comuns a todos os usuários (instrutor + aluno).
-- 1:1 com auth.users.
-- =====================================================================
create table profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  role              user_role       not null,
  full_name         text            not null,
  cpf               text            unique,
  birth_date        date,
  gender            gender,
  phone             text,
  avatar_url        text,
  -- MVP: trigger seta como 'approved' automaticamente.
  -- Fase paga: muda para 'pending' e painel admin aprova.
  approval_status   approval_status not null default 'approved',
  approved_at       timestamptz     default now(),
  rejected_reason   text,
  created_at        timestamptz     not null default now(),
  updated_at        timestamptz     not null default now()
);

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();

create index profiles_role_idx on profiles (role);
create index profiles_approval_idx on profiles (approval_status);

-- ---------------------------------------------------------------------
-- Trigger: criar profile automaticamente ao criar auth.users.
-- Metadados (role, full_name) vêm de raw_user_meta_data passado no signUp.
-- ---------------------------------------------------------------------
create or replace function handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, role, full_name)
  values (
    new.id,
    coalesce((new.raw_user_meta_data ->> 'role')::user_role, 'aluno'),
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- =====================================================================
-- TABELA: instructors
-- Dados específicos do instrutor. 1:1 com profiles.
-- =====================================================================
create table instructors (
  id                       uuid primary key references profiles (id) on delete cascade,
  bio                      text,

  -- Localização / área de atuação (sem mapa interativo no MVP)
  state                    text,                      -- UF
  city                     text,
  neighborhood             text,                      -- bairro principal
  service_radius_km        integer not null default 10,

  -- Documentos
  cnh_photo_url            text,                      -- foto da CNH do instrutor
  detran_certificate_url   text,                      -- foto do credenciamento DETRAN

  -- Veículo
  vehicle_type             vehicle_type   not null default 'carro',
  vehicle_brand            text,
  vehicle_model            text,
  vehicle_year             smallint,
  vehicle_transmission     transmission   not null default 'manual',
  vehicle_plate            text,
  vehicle_photo_front_url  text,
  vehicle_photo_back_url   text,

  -- Categorias de aula oferecidas (CNH categoria A, B, AB)
  categories               vehicle_category[] not null default '{}',

  -- Comercial (no MVP, sem markup/comissão)
  price_per_class          numeric(10, 2),

  -- Estado operacional
  is_active                boolean not null default true,  -- toggle "Ligado/Desligado" da tela AULA

  -- Reputação (cache mantido por triggers)
  average_rating           numeric(3, 2) not null default 0,
  total_reviews            integer       not null default 0,

  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);

create trigger instructors_set_updated_at
  before update on instructors
  for each row execute function set_updated_at();

create index instructors_location_idx on instructors (state, city);
create index instructors_active_idx   on instructors (is_active) where is_active = true;

-- =====================================================================
-- TABELA: students
-- Dados específicos do aluno. 1:1 com profiles.
-- =====================================================================
create table students (
  id                uuid primary key references profiles (id) on delete cascade,
  cnh_photo_url     text,                                -- foto da CNH/permissão do aluno
  desired_category  vehicle_category,                    -- categoria que está tirando
  state             text,
  city              text,

  -- Reputação (cache mantido por triggers — aluno também é avaliado)
  average_rating    numeric(3, 2) not null default 0,
  total_reviews     integer       not null default 0,

  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create trigger students_set_updated_at
  before update on students
  for each row execute function set_updated_at();

-- =====================================================================
-- TABELA: instructor_weekly_availability
-- Disponibilidade recorrente semanal do instrutor.
-- Ex: segunda-feira 14:00–18:00 → uma linha.
-- =====================================================================
create table instructor_weekly_availability (
  id              uuid primary key default gen_random_uuid(),
  instructor_id   uuid not null references instructors (id) on delete cascade,
  day_of_week     smallint not null check (day_of_week between 0 and 6),  -- 0=domingo
  start_time      time not null,
  end_time        time not null,
  created_at      timestamptz not null default now(),
  constraint avail_time_valid check (end_time > start_time)
);

create index avail_instructor_idx on instructor_weekly_availability (instructor_id, day_of_week);

-- =====================================================================
-- TABELA: bookings
-- Agendamentos de aulas entre aluno e instrutor.
-- =====================================================================
create table bookings (
  id                  uuid primary key default gen_random_uuid(),
  instructor_id       uuid not null references instructors (id) on delete restrict,
  student_id          uuid not null references students    (id) on delete restrict,

  scheduled_start     timestamptz not null,
  scheduled_end       timestamptz not null,
  status              booking_status not null default 'pending',

  meeting_point       text,                      -- onde se encontram
  notes               text,                      -- observações livres
  agreed_price        numeric(10, 2),            -- valor combinado (snapshot no momento)

  cancelled_by        uuid references profiles (id),
  cancellation_reason text,

  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint booking_time_valid check (scheduled_end > scheduled_start)
);

create trigger bookings_set_updated_at
  before update on bookings
  for each row execute function set_updated_at();

create index bookings_instructor_idx on bookings (instructor_id, scheduled_start desc);
create index bookings_student_idx    on bookings (student_id,    scheduled_start desc);
create index bookings_status_idx     on bookings (status);

-- =====================================================================
-- TABELA: conversations
-- Thread de chat entre um instrutor e um aluno (uma por par).
-- =====================================================================
create table conversations (
  id              uuid primary key default gen_random_uuid(),
  instructor_id   uuid not null references instructors (id) on delete cascade,
  student_id      uuid not null references students    (id) on delete cascade,
  last_message_at timestamptz,
  created_at      timestamptz not null default now(),
  unique (instructor_id, student_id)
);

create index conversations_instructor_idx on conversations (instructor_id, last_message_at desc);
create index conversations_student_idx    on conversations (student_id,    last_message_at desc);

-- =====================================================================
-- TABELA: chat_blocks
-- Bloqueios de chat. Quem bloqueou e quem foi bloqueado (uni-direcional).
-- =====================================================================
create table chat_blocks (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations (id) on delete cascade,
  blocker_id      uuid not null references profiles (id) on delete cascade,
  blocked_id      uuid not null references profiles (id) on delete cascade,
  reason          text,
  created_at      timestamptz not null default now(),
  unique (conversation_id, blocker_id)
);

create index chat_blocks_blocker_idx on chat_blocks (blocker_id);
create index chat_blocks_blocked_idx on chat_blocks (blocked_id);

-- =====================================================================
-- TABELA: messages
-- Mensagens individuais. Realtime ativado na publication do Supabase.
-- =====================================================================
create table messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references conversations (id) on delete cascade,
  sender_id       uuid not null references profiles (id) on delete cascade,
  content         text not null check (length(content) > 0 and length(content) <= 4000),
  read_at         timestamptz,
  created_at      timestamptz not null default now()
);

create index messages_conversation_idx on messages (conversation_id, created_at desc);
create index messages_unread_idx       on messages (conversation_id, read_at) where read_at is null;

-- ---------------------------------------------------------------------
-- Trigger: atualizar last_message_at na conversation ao receber mensagem
-- ---------------------------------------------------------------------
create or replace function update_conversation_last_message()
returns trigger
language plpgsql
as $$
begin
  update conversations
     set last_message_at = new.created_at
   where id = new.conversation_id;
  return new;
end;
$$;

create trigger messages_update_conversation
  after insert on messages
  for each row execute function update_conversation_last_message();

-- =====================================================================
-- TABELA: reviews
-- Avaliação bidirecional: aluno→instrutor e instrutor→aluno.
-- 1 avaliação por (booking, target) — aluno e instrutor podem avaliar
-- a mesma aula, cada um em uma linha.
-- =====================================================================
create table reviews (
  id            uuid primary key default gen_random_uuid(),
  booking_id    uuid not null references bookings (id) on delete cascade,
  reviewer_id   uuid not null references profiles (id) on delete cascade,  -- quem avalia
  reviewee_id   uuid not null references profiles (id) on delete cascade,  -- quem é avaliado
  target        review_target not null,        -- 'instructor' ou 'student'
  rating        smallint not null check (rating between 1 and 5),
  comment       text,
  created_at    timestamptz not null default now(),
  unique (booking_id, target)
);

create index reviews_reviewee_idx on reviews (reviewee_id, created_at desc);

-- ---------------------------------------------------------------------
-- Trigger: recalcular average_rating + total_reviews do avaliado
-- (instructor ou student) a cada insert/update/delete em reviews.
-- ---------------------------------------------------------------------
create or replace function recalc_reviewee_rating()
returns trigger
language plpgsql
as $$
declare
  target_id uuid;
  target_kind review_target;
begin
  target_id   := coalesce(new.reviewee_id, old.reviewee_id);
  target_kind := coalesce(new.target,      old.target);

  if target_kind = 'instructor' then
    update instructors
       set average_rating = coalesce((
             select round(avg(rating)::numeric, 2)
               from reviews
              where reviewee_id = target_id and target = 'instructor'
           ), 0),
           total_reviews = (
             select count(*)
               from reviews
              where reviewee_id = target_id and target = 'instructor'
           )
     where id = target_id;
  else
    update students
       set average_rating = coalesce((
             select round(avg(rating)::numeric, 2)
               from reviews
              where reviewee_id = target_id and target = 'student'
           ), 0),
           total_reviews = (
             select count(*)
               from reviews
              where reviewee_id = target_id and target = 'student'
           )
     where id = target_id;
  end if;

  return null;
end;
$$;

create trigger reviews_recalc_rating
  after insert or update or delete on reviews
  for each row execute function recalc_reviewee_rating();

-- =====================================================================
-- Storage buckets (criados via dashboard do Supabase ou CLI separadamente;
-- documentados aqui como referência)
--
--   • avatars         — fotos de perfil (público)
--   • vehicle-photos  — fotos do veículo do instrutor (público)
--   • documents       — CNH, certificado DETRAN (privado, acesso via RLS)
-- =====================================================================

-- =====================================================================
-- FIM da migration 0001_initial_schema
-- =====================================================================
