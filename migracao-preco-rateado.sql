-- Rodar no SQL Editor do Supabase do Agropecuária Pontual.
-- Marca se o "Preço de compra (R$/kg)" do animal foi preenchido automaticamente
-- pelo botão de distribuir valor da compra (true) ou digitado à mão (false).
-- Isso permite clicar o botão várias vezes, conforme novos animais da mesma
-- compra vão sendo cadastrados, sem perder preços que já foram editados manualmente
-- nem sem inflar o total distribuído acima do valor real da compra.

alter table animais add column if not exists preco_rateado boolean not null default false;
