// ============================================================
// Agropecuária Pontual — Sidebar / navegação compartilhada
// ============================================================

(function aplicarTemaSalvo() {
  const temaSalvo = localStorage.getItem('pontual-tema') || 'dark';
  document.documentElement.setAttribute('data-theme', temaSalvo);
})();

const MENU_ITEMS = [
  { page: 'painel',     label: 'Painel',     icon: 'ti-layout-dashboard' },
  { page: 'fazendas',   label: 'Fazendas',   icon: 'ti-building-warehouse' },
  { page: 'animais',    label: 'Animais',    img: 'logo-pontual.png' },
  { page: 'lotes',      label: 'Lotes',      icon: 'ti-stack-2' },
  { page: 'mangas',     label: 'Mangas',     icon: 'ti-fence' },
  { page: 'compras',    label: 'Compras',    icon: 'ti-shopping-cart' },
  { page: 'vendas',     label: 'Vendas',     icon: 'ti-currency-dollar' },
  { page: 'relatorios', label: 'Relatórios', icon: 'ti-chart-bar' },
];

function renderTopbarSidebar(activePage) {
  const itemsHtml = MENU_ITEMS.map(item => `
    <button class="sitem ${item.page === activePage ? 'active' : ''}" title="${item.label}" onclick="location.href='${item.page}.html'">
      ${item.img ? `<img src="${item.img}" class="sitem-icon-img" width="18" height="15">` : `<i class="ti ${item.icon}"></i>`}<span>${item.label}</span>
    </button>
  `).join('');

  const temaAtual = document.documentElement.getAttribute('data-theme') || 'dark';
  const sidebarColapsado = localStorage.getItem('pontual-sidebar') === 'collapsed';

  document.body.insertAdjacentHTML('afterbegin', `
    <div class="topbar">
      <button class="menubtn" onclick="toggleSidebar()" title="Minimizar/expandir menu"><i class="ti ti-menu-2"></i></button>
      <img src="logo-pontual.png" alt="Agropecuária Pontual" class="brand-logo">
      <div class="brand"><img src="logo-pontual.png" class="brand-icon" width="22" height="18"> Agropecuária Pontual</div>
      <div class="spacer"></div>
      <button class="theme-toggle" id="themeToggleBtn" onclick="alternarTema()" title="Alternar tema claro/escuro">
        <i class="ti ${temaAtual === 'light' ? 'ti-moon' : 'ti-sun'}" id="themeToggleIcon"></i>
      </button>
      <div class="user-info">
        <span id="userEmail"></span>
        <button class="logout-btn" onclick="logout()">Sair</button>
      </div>
    </div>
    <div class="body-layout">
      <div class="sidebar ${sidebarColapsado ? 'collapsed' : ''}" id="sidebar">
        <div class="snav">${itemsHtml}</div>
      </div>
      <div class="main" id="mainContent"></div>
    </div>
  `);
}

function alternarTema() {
  const atual = document.documentElement.getAttribute('data-theme') || 'dark';
  const novo = atual === 'light' ? 'dark' : 'light';
  document.documentElement.setAttribute('data-theme', novo);
  localStorage.setItem('pontual-tema', novo);
  const icone = document.getElementById('themeToggleIcon');
  if (icone) icone.className = `ti ${novo === 'light' ? 'ti-moon' : 'ti-sun'}`;
}

function toggleSidebar() {
  const colapsado = document.getElementById('sidebar').classList.toggle('collapsed');
  localStorage.setItem('pontual-sidebar', colapsado ? 'collapsed' : 'expanded');
}

async function showUserEmail() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (session) {
    document.getElementById('userEmail').textContent = session.user.email;
  }
}

// ============================================================
// Busca paginada — o Supabase limita cada consulta a 1000 linhas
// por padrão. `criarQuery` deve retornar um builder novo (com os
// filtros/ordenação já aplicados) a cada chamada, sem `.range()`.
// ============================================================
async function buscarPaginado(criarQuery) {
  const LOTE = 1000;
  let pagina = 0, todos = [];
  while (true) {
    const { data, error } = await criarQuery().range(pagina * LOTE, pagina * LOTE + LOTE - 1);
    if (error) throw error;
    todos = todos.concat(data || []);
    if (!data || data.length < LOTE) break;
    pagina++;
  }
  return todos;
}
