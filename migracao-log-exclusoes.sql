-- Tabela de log de exclusões de animais (guarda os dados completos do animal e
-- das pesagens dele no momento em que foi excluído, pra consulta/exportação depois).
-- Rode isso uma vez no SQL Editor do Supabase.

create table if not exists log_exclusoes (
  id uuid primary key default gen_random_uuid(),
  criado_em timestamptz not null default now(),
  usuario text,
  quantidade int not null,
  animais jsonb not null,
  pesagens jsonb
);

alter table log_exclusoes disable row level security;
