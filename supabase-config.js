// ============================================================
// Agropecuária Pontual — Configuração do Supabase
// Inclua este arquivo em todas as páginas, antes dos demais scripts
// ============================================================

const SUPABASE_URL = 'https://exfurpojaaqpwmgxsirg.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV4ZnVycG9qYWFxcHdtZ3hzaXJnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU5NDkzODEsImV4cCI6MjEwMTUyNTM4MX0.kStuq6RkAkKfDDvGVs63Q3gMLAi0o2MfTm1aQ_FQleo';

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// ------------------------------------------------------------
// Proteção de página: redireciona para login se não autenticado
// Chame checkAuth() no topo de toda página exceto login.html
// ------------------------------------------------------------
async function checkAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = 'login.html';
    return null;
  }
  return session;
}

async function logout() {
  await supabaseClient.auth.signOut();
  window.location.href = 'login.html';
}
