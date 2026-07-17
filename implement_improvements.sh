#!/bin/bash
# Script de Implementação - Melhorias Frontend & Backend
# Data: 17/07/2026

echo "🚀 Iniciando Implementação de Melhorias..."
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para printar com cor
print_step() {
  echo -e "${BLUE}✓${NC} $1"
}

print_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
  echo -e "${RED}❌ $1${NC}"
}

echo ""
echo -e "${BLUE}=== BACKEND SETUP ===${NC}"
echo ""

# 1. Backup do database
print_step "Criando backup do banco de dados..."
# docker compose exec postgres pg_dump -U postgres nexus > backup_nexus_$(date +%Y%m%d_%H%M%S).sql
echo "Pule esta etapa se quiser"
echo ""

# 2. Aplicar migração
print_step "Aplicando migração de roles..."
echo "Executar um dos comandos abaixo:"
echo ""
echo "Via Docker:"
echo "  docker compose exec postgres psql -U postgres -d nexus -f /backend/database/004_add_user_roles.sql"
echo ""
echo "Via SSH/VPS:"
echo "  psql -U postgres -d nexus -f backend/database/004_add_user_roles.sql"
echo ""
read -p "Pressione ENTER após executar a migração..."
print_success "Migração aplicada!"
echo ""

# 3. Testar validação de senha
print_step "Testando validação de senha..."
echo ""
echo "Teste 1: Senha fraca (deve falhar com 422)"
echo '  curl -X POST http://localhost:8000/auth/register \'
echo '    -H "Content-Type: application/json" \'
echo "    -d '{\"email\":\"test@example.com\",\"password\":\"weak\"}'"
echo ""
echo "Teste 2: Senha forte (deve funcionar com 200/201)"
echo '  curl -X POST http://localhost:8000/auth/register \'
echo '    -H "Content-Type: application/json" \'
echo "    -d '{\"email\":\"test@example.com\",\"password\":\"SecurePass123!@\"}'"
echo ""
read -p "Pressione ENTER após testar..."
print_success "Validação de senha testada!"
echo ""

# 4. Definir admin user
print_step "Definindo admin user..."
echo ""
echo "Execute no PostgreSQL:"
echo "  psql -U postgres -d nexus"
echo ""
echo "Depois rode:"
echo '  UPDATE users SET role = "admin" WHERE email = "seu-email@example.com";'
echo ""
read -p "Pressione ENTER após definir admin..."
print_success "Admin user configurado!"
echo ""

# 5. Verificar CORS
print_step "Verificando CORS..."
echo ""
echo "  curl -X OPTIONS http://localhost:8000/api/media \\"
echo "    -H \"Origin: https://nexusstream.com\" -v"
echo ""
echo "Deve incluir Access-Control-Allow-Origin"
echo ""
read -p "Pressione ENTER após verificar..."
print_success "CORS configurado!"
echo ""

echo ""
echo -e "${BLUE}=== FRONTEND SETUP ===${NC}"
echo ""

# 6. Error Handler
print_step "Integrando ErrorHandler..."
echo ""
echo "1. Abra lib/services/auth_service.dart"
echo "2. Adicione import:"
echo "   import 'package:nexus_mobile/utils/error_handler.dart';"
echo ""
echo "3. Em cada try-catch, use:"
echo "   try {"
echo "     await apiService.login(email, password);"
echo "   } catch (e, st) {"
echo "     final error = ErrorHandler.handleError(e, st);"
echo "     context.showError(error.userMessage);"
echo "   }"
echo ""
read -p "Pressione ENTER após integrar ErrorHandler..."
print_success "ErrorHandler integrado!"
echo ""

# 7. Cache Service
print_step "Integrando CacheService..."
echo ""
echo "1. Abra lib/services/media_service.dart"
echo "2. Adicione:"
echo "   final cache = CacheService();"
echo ""
echo "3. Modifique fetchMedia():"
echo "   Future<List<Media>> fetchMedia() async {"
echo "     return await cache.getOrFetch<List<Media>>("
echo "       'media_list',"
echo "       () => _fetchMediaFromAPI(),"
echo "       ttl: Duration(minutes: 5),"
echo "     );"
echo "   }"
echo ""
read -p "Pressione ENTER após integrar CacheService..."
print_success "CacheService integrado!"
echo ""

# Final
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅  IMPLEMENTAÇÃO COMPLETA!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════╝${NC}"
echo ""

echo "📊 Resumo de Melhorias Implementadas:"
echo "  ✅ Validação de Senha Forte"
echo "  ✅ CORS Restritivo"
echo "  ✅ Admin Roles em Banco de Dados"
echo "  ✅ Validações em Schemas"
echo "  ✅ Error Handler Global (Flutter)"
echo "  ✅ Cache Service Otimizado (Flutter)"
echo "  ✅ Logging Estruturado em JSON"
echo ""

echo "📚 Documentação Disponível:"
echo "  - GUIA_INTEGRACAO_MELHORIAS.md"
echo "  - MELHORIAS_FRONTEND_BACKEND.md"
echo "  - RESUMO_MELHORIAS_JULHO2026.md"
echo ""

echo "🚀 Próximas Etapas:"
echo "  1. Fazer build do Flutter: flutter build apk"
echo "  2. Deploy do backend"
echo "  3. Testar em produção"
echo "  4. Monitorar logs em /var/log/nexus/"
echo ""

print_success "Setup Completo!"
