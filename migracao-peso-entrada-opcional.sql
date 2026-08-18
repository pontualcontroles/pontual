-- Rodar no SQL Editor do Supabase do Agropecuária Pontual.
-- Permite cadastrar/importar animais sem peso de entrada (o boi às vezes
-- só é pesado alguns dias depois de chegar). custo_total fica nulo
-- nesses casos, já que depende do peso — é recalculado sozinho quando
-- o peso for informado depois.

alter table animais alter column peso_entrada drop not null;
