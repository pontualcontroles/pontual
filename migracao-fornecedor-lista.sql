-- Rodar no SQL Editor do Supabase do Agropecuária Pontual.
-- Adiciona compra_id e o nome do fornecedor (vendedor da compra vinculada)
-- na view usada pela lista de Animais, pra aparecer na tela — igual ao TopBoi.

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
  end as lucro,
  a.compra_id,
  c.vendedor as fornecedor
from animais a
left join fazendas f on f.id = a.fazenda_id
left join lotes l on l.id = a.lote_id
left join mangas m on m.id = a.manga_id
left join compras c on c.id = a.compra_id;
