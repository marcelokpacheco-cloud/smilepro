-- SmilePro Gestão: schema completo (pode rodar mais de uma vez sem erro)
create table if not exists pacientes(
  id uuid primary key default gen_random_uuid(),
  nome text not null, telefone text, nascimento date, historico text,
  dentes jsonb default '{}', created_at timestamptz default now());
create table if not exists consultas(
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid references pacientes(id) on delete cascade,
  paciente_nome text, data date, hora time, procedimento text,
  valor numeric default 0, status text default 'agendada',
  pago boolean default false, created_at timestamptz default now());
create table if not exists leads(
  id uuid primary key default gen_random_uuid(),
  nome text not null, telefone text, origem text, interesse text,
  etapa text default 'Novo', created_at timestamptz default now());
create table if not exists pesquisas(
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid references pacientes(id) on delete set null,
  paciente_nome text, nota int check (nota between 0 and 10),
  comentario text, created_at timestamptz default now());
create table if not exists mensagens_log(
  id uuid primary key default gen_random_uuid(),
  tipo text, ref text, paciente_nome text, created_at timestamptz default now());
create table if not exists profissionais(
  id uuid primary key default gen_random_uuid(),
  nome text not null, cro text, cor text default '#0f766e',
  created_at timestamptz default now());
alter table consultas
  add column if not exists profissional_id uuid references profissionais(id) on delete set null,
  add column if not exists profissional_nome text,
  add column if not exists cadeira text,
  add column if not exists duracao int default 30,
  add column if not exists google_event_id text,
  add column if not exists google_sig text;
alter table pacientes add column if not exists anamnese jsonb default '{}';
create table if not exists orcamentos(
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid references pacientes(id) on delete cascade, paciente_nome text,
  itens jsonb default '[]', desconto numeric default 0, status text default 'aberto',
  created_at timestamptz default now());
create table if not exists evolucoes(
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid references pacientes(id) on delete cascade,
  profissional_nome text, texto text not null, created_at timestamptz default now());
create table if not exists fotos(
  id uuid primary key default gen_random_uuid(),
  paciente_id uuid references pacientes(id) on delete cascade,
  path text not null, legenda text, created_at timestamptz default now());
do $$ declare t text; begin
  foreach t in array array['pacientes','consultas','leads','pesquisas','mensagens_log','profissionais','orcamentos','evolucoes','fotos'] loop
    execute format('alter table %I enable row level security',t);
    execute format('drop policy if exists "auth_all" on %I',t);
    execute format('create policy "auth_all" on %I for all to authenticated using(true) with check(true)',t);
  end loop; end $$;
insert into storage.buckets(id,name,public) values('fotos-pacientes','fotos-pacientes',false)
  on conflict (id) do nothing;
drop policy if exists "fotos_auth" on storage.objects;
create policy "fotos_auth" on storage.objects for all to authenticated
  using(bucket_id='fotos-pacientes') with check(bucket_id='fotos-pacientes');
notify pgrst, 'reload schema';
