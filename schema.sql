-- ============================================================
-- Agropecuária Pontual — Schema completo (Supabase / PostgreSQL)
-- Controle interno de fazendas, mangas, lotes, animais, peso,
-- compras e vendas
-- ============================================================

-- ============================================================
-- 1. TABELAS
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 FAZENDAS
-- ------------------------------------------------------------
create table if not exists fazendas (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  proprietario text,
  atividade text check (atividade in ('Engorda','Cria','Recria','Cria e recria','Confinamento','Misto')),
  capacidade integer,
  municipio text,
  estado text,
  endereco text,
  area_total_ha numeric,
  area_produtiva_ha numeric,
  animais_sem_cadastro integer not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 1.2 MANGAS (currais/piquetes de uma fazenda)
-- ------------------------------------------------------------
create table if not exists mangas (
  id uuid primary key default gen_random_uuid(),
  numero text not null,
  fazenda_id uuid not null references fazendas(id) on delete cascade,
  capacidade integer not null,
  tipo_estrutura text check (tipo_estrutura in ('Curral','Piquete','Galpão')),
  created_at timestamptz default now(),
  unique(fazenda_id, numero)
);

create index if not exists idx_mangas_fazenda on mangas(fazenda_id);

-- ------------------------------------------------------------
-- 1.3 LOTES
-- ------------------------------------------------------------
create table if not exists lotes (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  fazenda_id uuid references fazendas(id) on delete set null,
  categoria text check (categoria in ('Bezerro','Garrote','Novilho','Boi','Vaca','Misto')),
  data_formacao date,
  created_at timestamptz default now()
);

create index if not exists idx_lotes_fazenda on lotes(fazenda_id);

-- ------------------------------------------------------------
-- 1.4 COMPRAS (lote de animais adquirido de um vendedor)
-- ------------------------------------------------------------
create table if not exists compras (
  id uuid primary key default gen_random_uuid(),
  codigo integer,
  data_compra date not null,
  vendedor text,
  nota_fiscal text,
  valor_total numeric(12,2),
  frete_total numeric(10,2) default 0,
  valor_comissao numeric(10,2),
  forma_pagamento text,
  observacoes text,
  created_at timestamptz default now()
);

create sequence if not exists compras_codigo_seq;
alter table compras alter column codigo set default nextval('compras_codigo_seq');
alter sequence compras_codigo_seq owned by compras.codigo;
alter table compras alter column codigo set not null;
alter table compras add constraint compras_codigo_key unique (codigo);

-- ------------------------------------------------------------
-- 1.5 COMPRAS_PARCELAS
-- ------------------------------------------------------------
create table if not exists compras_parcelas (
  id uuid primary key default gen_random_uuid(),
  compra_id uuid not null references compras(id) on delete cascade,
  numero_parcela integer not null,
  valor numeric(12,2) not null,
  vencimento date not null,
  pago boolean not null default false,
  data_pagamento date,
  created_at timestamptz default now()
);

create index if not exists idx_compras_parcelas_compra on compras_parcelas(compra_id);

-- ------------------------------------------------------------
-- 1.6 VENDAS (lote de animais vendido a um comprador)
-- ------------------------------------------------------------
create table if not exists vendas (
  id uuid primary key default gen_random_uuid(),
  data_venda date not null,
  comprador text,
  nota_fiscal text,
  valor_total numeric(12,2),
  frete_total numeric(10,2) default 0,
  forma_recebimento text,
  observacoes text,
  created_at timestamptz default now()
);

-- ------------------------------------------------------------
-- 1.7 VENDAS_PARCELAS
-- ------------------------------------------------------------
create table if not exists vendas_parcelas (
  id uuid primary key default gen_random_uuid(),
  venda_id uuid not null references vendas(id) on delete cascade,
  numero_parcela integer not null,
  valor numeric(12,2) not null,
  vencimento date not null,
  recebido boolean not null default false,
  data_recebimento date,
  created_at timestamptz default now()
);

create index if not exists idx_vendas_parcelas_venda on vendas_parcelas(venda_id);

-- ------------------------------------------------------------
-- 1.8 ANIMAIS
-- ------------------------------------------------------------
create table if not exists animais (
  id uuid primary key default gen_random_uuid(),
  brinco text not null unique,
  fazenda_id uuid references fazendas(id) on delete set null,
  lote_id uuid references lotes(id) on delete set null,
  manga_id uuid references mangas(id) on delete set null,
  sexo text not null check (sexo in ('Macho','Fêmea')),
  raca text,
  pelagem text,
  marca text,
  categoria text check (categoria in ('Bezerro','Bezerra','Garrote','Novilha','Novilho','Vaca','Boi','Touro','Matrona','Vaca seca')),
  data_nascimento date,
  data_desmame date,

  -- entrada / compra
  data_entrada date not null,
  peso_entrada numeric(8,2) not null,
  castrado boolean default false,
  produtor_origem text,
  preco_compra_kg numeric(10,2),
  frete_compra numeric(10,2) default 0,
  custo_total numeric(10,2) generated always as
    (peso_entrada * coalesce(preco_compra_kg,0) + coalesce(frete_compra,0)) stored,
  compra_id uuid references compras(id) on delete set null,

  -- saída / venda
  status text not null default 'ativo' check (status in ('ativo','vendido','morto')),
  data_venda date,
  peso_saida numeric(8,2),
  preco_venda numeric(10,2),
  comprador text,
  venda_id uuid references vendas(id) on delete set null,

  -- baixa
  data_morte date,
  causa_morte text check (causa_morte in ('Doença','Acidente','Predador','Desconhecida')),

  observacoes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_animais_fazenda on animais(fazenda_id);
create index if not exists idx_animais_lote on animais(lote_id);
create index if not exists idx_animais_manga on animais(manga_id);
create index if not exists idx_animais_status on animais(status);
create index if not exists idx_animais_origem on animais(produtor_origem);
create index if not exists idx_animais_compra on animais(compra_id);
create index if not exists idx_animais_venda on animais(venda_id);

-- ------------------------------------------------------------
-- 1.9 PESAGENS
-- ------------------------------------------------------------
create table if not exists pesagens (
  id uuid primary key default gen_random_uuid(),
  animal_id uuid not null references animais(id) on delete cascade,
  data_pesagem date not null,
  peso numeric(8,2) not null,
  gmd_periodo numeric(6,3),
  gmd_acumulado numeric(6,3),
  origem_lancamento text default 'manual' check (origem_lancamento in ('manual','planilha')),
  created_at timestamptz default now(),
  unique(animal_id, data_pesagem)
);

create index if not exists idx_pesagens_animal on pesagens(animal_id, data_pesagem);

-- ============================================================
-- 2. FUNÇÕES E TRIGGERS — cálculo automático de GMD
-- ============================================================

create or replace function recalcular_pesagens_animal(p_animal_id uuid)
returns void as $$
declare
  v_peso_anterior numeric(8,2);
  v_data_anterior date;
  v_peso_entrada numeric(8,2);
  v_data_entrada date;
  v_row record;
begin
  select peso_entrada, data_entrada into v_peso_entrada, v_data_entrada
  from animais where id = p_animal_id;

  v_peso_anterior := v_peso_entrada;
  v_data_anterior := v_data_entrada;

  for v_row in
    select id, data_pesagem, peso
    from pesagens
    where animal_id = p_animal_id
    order by data_pesagem asc
  loop
    update pesagens
    set
      gmd_periodo = case
        when v_row.data_pesagem > v_data_anterior
        then round((v_row.peso - v_peso_anterior) / (v_row.data_pesagem - v_data_anterior), 3)
        else null
      end,
      gmd_acumulado = case
        when v_row.data_pesagem > v_data_entrada
        then round((v_row.peso - v_peso_entrada) / (v_row.data_pesagem - v_data_entrada), 3)
        else null
      end
    where id = v_row.id;

    v_peso_anterior := v_row.peso;
    v_data_anterior := v_row.data_pesagem;
  end loop;
end;
$$ language plpgsql;

create or replace function trg_fn_pesagem_alterada()
returns trigger as $$
begin
  perform recalcular_pesagens_animal(coalesce(new.animal_id, old.animal_id));
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_pesagem_alterada on pesagens;
create trigger trg_pesagem_alterada
after insert or update or delete on pesagens
for each row execute function trg_fn_pesagem_alterada();

create or replace function trg_fn_animal_corrigido()
returns trigger as $$
begin
  if (new.peso_entrada is distinct from old.peso_entrada)
     or (new.data_entrada is distinct from old.data_entrada) then
    perform recalcular_pesagens_animal(new.id);
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_animal_corrigido on animais;
create trigger trg_animal_corrigido
after update on animais
for each row execute function trg_fn_animal_corrigido();

-- ============================================================
-- 3. VIEWS — alimentam Painel, Listagem e Relatórios
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Resumo por animal (peso atual, ganho, dias, lucro)
-- ------------------------------------------------------------
create or replace view vw_animais_resumo as
select
  a.id,
  a.brinco,
  a.fazenda_id,
  f.nome as fazenda_nome,
  a.lote_id,
  l.nome as lote_nome,
  a.manga_id,
  m.numero as manga_numero,
  a.sexo,
  a.raca,
  a.categoria,
  a.status,
  a.data_entrada,
  a.peso_entrada,
  a.produtor_origem,
  a.custo_total,
  coalesce(
    (select p.peso from pesagens p
     where p.animal_id = a.id
     order by p.data_pesagem desc limit 1),
    a.peso_entrada
  ) as peso_atual,
  coalesce(
    (select p.peso from pesagens p
     where p.animal_id = a.id
     order by p.data_pesagem desc limit 1),
    a.peso_entrada
  ) - a.peso_entrada as ganho_total,
  coalesce(
    (select p.gmd_acumulado from pesagens p
     where p.animal_id = a.id
     order by p.data_pesagem desc limit 1),
    null
  ) as gmd_atual,
  case
    when a.status = 'ativo' then (current_date - a.data_entrada)
    when a.status = 'vendido' then (a.data_venda - a.data_entrada)
    else (a.data_morte - a.data_entrada)
  end as dias_no_ciclo,
  case
    when a.status = 'vendido'
    then a.preco_venda - a.custo_total
    else null
  end as lucro
from animais a
left join fazendas f on f.id = a.fazenda_id
left join lotes l on l.id = a.lote_id
left join mangas m on m.id = a.manga_id;

-- ------------------------------------------------------------
-- 3.2 Relatório agrupado por fornecedor/origem
-- ------------------------------------------------------------
create or replace view vw_relatorio_origem as
select
  v.produtor_origem,
  count(*) as qtd_animais,
  count(*) filter (where v.status = 'vendido') as qtd_vendidos,
  sum(v.custo_total) as total_comprado,
  sum(a.preco_venda) filter (where v.status = 'vendido') as total_vendido,
  sum(v.lucro) filter (where v.status = 'vendido') as lucro_total,
  round(avg(v.gmd_atual), 3) as gmd_medio
from vw_animais_resumo v
join animais a on a.id = v.id
group by v.produtor_origem
order by lucro_total desc nulls last;

-- ------------------------------------------------------------
-- 3.3 Resumo por lote (animais ativos, peso total, GMD médio)
-- ------------------------------------------------------------
create or replace view vw_lotes_resumo as
select
  l.id,
  l.nome,
  l.fazenda_id,
  f.nome as fazenda_nome,
  l.categoria,
  count(a.id) filter (where a.status = 'ativo') as animais_ativos,
  sum(coalesce(
    (select p.peso from pesagens p where p.animal_id = a.id order by p.data_pesagem desc limit 1),
    a.peso_entrada
  )) filter (where a.status = 'ativo') as peso_total,
  round(avg(
    (select p.gmd_acumulado from pesagens p where p.animal_id = a.id order by p.data_pesagem desc limit 1)
  ) filter (where a.status = 'ativo'), 3) as gmd_medio
from lotes l
left join fazendas f on f.id = l.fazenda_id
left join animais a on a.lote_id = l.id
group by l.id, l.nome, l.fazenda_id, f.nome, l.categoria;

-- ------------------------------------------------------------
-- 3.4 Ocupação das mangas
-- ------------------------------------------------------------
create or replace view vw_mangas_ocupacao as
select
  m.id,
  m.numero,
  m.fazenda_id,
  f.nome as fazenda_nome,
  m.capacidade,
  count(a.id) filter (where a.status = 'ativo') as ocupacao_atual,
  round(
    100.0 * count(a.id) filter (where a.status = 'ativo') / nullif(m.capacidade, 0),
    1
  ) as percentual_ocupacao
from mangas m
left join fazendas f on f.id = m.fazenda_id
left join animais a on a.manga_id = m.id
group by m.id, m.numero, m.fazenda_id, f.nome, m.capacidade;

-- ------------------------------------------------------------
-- 3.5 Resumo por compra (animais vinculados, peso, parcelas)
-- ------------------------------------------------------------
create or replace view vw_compras_resumo as
select
  c.id,
  c.data_compra,
  c.vendedor,
  c.nota_fiscal,
  c.valor_total,
  c.frete_total,
  c.forma_pagamento,
  c.observacoes,
  c.valor_comissao,
  count(a.id) as qtd_animais,
  sum(a.peso_entrada) as peso_total_entrada,
  (select count(*) from compras_parcelas cp where cp.compra_id = c.id) as parcelas_total,
  (select count(*) from compras_parcelas cp where cp.compra_id = c.id and cp.pago) as parcelas_pagas,
  (select coalesce(sum(cp.valor),0) from compras_parcelas cp where cp.compra_id = c.id and cp.pago) as valor_pago,
  (select coalesce(sum(cp.valor),0) from compras_parcelas cp where cp.compra_id = c.id and not cp.pago) as valor_pendente
from compras c
left join animais a on a.compra_id = c.id
group by c.id, c.data_compra, c.vendedor, c.nota_fiscal, c.valor_total, c.frete_total, c.forma_pagamento, c.observacoes, c.valor_comissao;

-- ------------------------------------------------------------
-- 3.6 Resumo por venda (animais vinculados, peso, custo, lucro, parcelas)
-- ------------------------------------------------------------
create or replace view vw_vendas_resumo as
select
  v.id,
  v.data_venda,
  v.comprador,
  v.nota_fiscal,
  v.valor_total,
  v.frete_total,
  v.forma_recebimento,
  v.observacoes,
  count(a.id) as qtd_animais,
  sum(a.peso_saida) as peso_total_saida,
  sum(a.custo_total) as custo_total_animais,
  v.valor_total - coalesce(sum(a.custo_total), 0) as lucro_bruto,
  (select count(*) from vendas_parcelas vp where vp.venda_id = v.id) as parcelas_total,
  (select count(*) from vendas_parcelas vp where vp.venda_id = v.id and vp.recebido) as parcelas_recebidas,
  (select coalesce(sum(vp.valor),0) from vendas_parcelas vp where vp.venda_id = v.id and vp.recebido) as valor_recebido,
  (select coalesce(sum(vp.valor),0) from vendas_parcelas vp where vp.venda_id = v.id and not vp.recebido) as valor_a_receber
from vendas v
left join animais a on a.venda_id = v.id
group by v.id, v.data_venda, v.comprador, v.nota_fiscal, v.valor_total, v.frete_total, v.forma_recebimento, v.observacoes;

-- ============================================================
-- 4. RLS (Row Level Security)
-- ============================================================

alter table fazendas enable row level security;
alter table mangas enable row level security;
alter table lotes enable row level security;
alter table animais enable row level security;
alter table pesagens enable row level security;
alter table compras enable row level security;
alter table compras_parcelas enable row level security;
alter table vendas enable row level security;
alter table vendas_parcelas enable row level security;

create policy "Usuários autenticados podem tudo em fazendas"
on fazendas for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em mangas"
on mangas for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em lotes"
on lotes for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em animais"
on animais for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em pesagens"
on pesagens for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em compras"
on compras for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em compras_parcelas"
on compras_parcelas for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em vendas"
on vendas for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');

create policy "Usuários autenticados podem tudo em vendas_parcelas"
on vendas_parcelas for all
using (auth.role() = 'authenticated')
with check (auth.role() = 'authenticated');
