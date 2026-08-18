-- ============================================================
-- Agropecuária Pontual — Zera TODO o banco (apaga todos os dados
-- de todas as tabelas, mantendo a estrutura/schema intacta).
--
-- USE COM CUIDADO: isso é IRREVERSÍVEL. Rode uma vez no SQL Editor
-- do Supabase só depois de ter certeza de que quer apagar os dados
-- fictícios de teste.
-- ============================================================

truncate table
  fazendas,
  mangas,
  lotes,
  compras,
  compras_parcelas,
  vendas,
  vendas_parcelas,
  animais,
  pesagens
restart identity cascade;

-- log_exclusoes só existe se você já rodou migracao-log-exclusoes.sql;
-- limpa ela também nesse caso, sem quebrar o script se ainda não existir.
do $$
begin
  if exists (select 1 from information_schema.tables where table_name = 'log_exclusoes') then
    execute 'truncate table log_exclusoes restart identity cascade';
  end if;
end $$;
