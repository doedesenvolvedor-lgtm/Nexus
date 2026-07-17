# 🚀 Guia de Integração - Melhorias Frontend & Backend

## ✅ Melhorias Implementadas

### Backend (FastAPI)

#### 1. ✨ Validação de Senha Forte
**Arquivo:** `backend/app/schemas.py`

**O que mudou:**
- Senhas agora requerem:
  - Mínimo 12 caracteres
  - Pelo menos 1 maiúscula
  - Pelo menos 1 minúscula
  - Pelo menos 1 dígito
  - Pelo menos 1 caractere especial (@$!%*?&)

**Como usar:**
```python
# Qualquer tentativa de criar usuário com senha fraca será rejeitada
from app.schemas import UserCreate

# ❌ Será rejeitado
user = UserCreate(
    email="user@example.com",
    password="12345"  # Muito curto e fraco
)

# ✅ Será aceito
user = UserCreate(
    email="user@example.com",
    password="SecurePass123!@"
)
```

#### 2. 🔒 CORS Restritivo
**Arquivo:** `backend/app/main.py`

**O que mudou:**
- Remove wildcard `*` em `allow_methods` e `allow_headers`
- Define apenas métodos necessários: GET, POST, PUT, DELETE, PATCH, OPTIONS
- Headers específicos: Authorization, Content-Type, X-Request-ID, Accept

**Benefício:** Reduz superfície de ataque contra CSRF e XSS

#### 3. 👥 Admin Roles em Banco de Dados
**Arquivos:** 
- `backend/app/models.py` - Adicionado campo `role`
- `backend/app/security_admin.py` - Lógica atualizada
- `backend/database/004_add_user_roles.sql` - Migração

**Roles disponíveis:**
- `user` (padrão): Usuário comum
- `moderator`: Pode moderar conteúdo
- `admin`: Acesso total

**Como usar:**
```python
# No código
from app.security_admin import get_admin_user
from fastapi import Depends

@router.delete("/admin/users/{user_id}")
async def delete_user(user_id: str, admin: User = Depends(get_admin_user)):
    # Apenas admins podem acessar
    pass

# No banco de dados
# UPDATE users SET role = 'admin' WHERE email = 'seu-email@example.com';
```

**Executar migração:**
```bash
# Dentro do container ou VPS
psql -U postgres -d nexus -f backend/database/004_add_user_roles.sql
```

#### 4. 📋 Validações em Schemas
**Arquivo:** `backend/app/schemas.py`

**Adicionado:**
- `min_length`, `max_length` em todos os campos de texto
- Regex patterns para username, rating, content_type
- Validação de PIN (4 dígitos)
- Constraints numéricos (ano de lançamento, duração, etc)

**Exemplo:**
```python
class MediaCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255)
    description: str = Field(..., min_length=10, max_length=2000)
    content_type: str = Field(..., regex=r'^(movie|series|documentary|special)$')
    release_year: int = Field(..., ge=1900, le=2100)
    duration: int = Field(..., gt=0, le=14400)  # até 4 horas
    rating: str = Field(..., regex=r'^(G|PG|PG-13|R|NC-17|L| 10|12|14|16|18)$')
```

#### 5. 📊 Logging Estruturado em JSON
**Arquivo:** `backend/app/logging_config_improved.py`

**Recursos:**
- Logs em JSON estruturado (compatível com CloudWatch, ELK)
- Rastreamento de requisição com `request_id`
- Contexto do usuário e endpoint
- Duração das operações

**Como integrar:**
```python
# Substituir no main.py
from app.logging_config_improved import setup_logging

logger = setup_logging()

# Usar em qualquer lugar do código
logger = logging.getLogger(__name__)
logger.info("Evento importante", extra={
    "request_id": "abc123",
    "user_id": "user456",
    "endpoint": "/api/media",
})
```

**Exemplo de log gerado:**
```json
{
  "timestamp": "2026-07-17T10:30:45.123Z",
  "level": "INFO",
  "logger": "app.routers.auth",
  "message": "Usuário login bem-sucedido",
  "environment": "production",
  "request_id": "abc123",
  "user_id": "user456",
  "endpoint": "/auth/login",
  "method": "POST",
  "status_code": 200,
  "duration_ms": 245
}
```

---

### Frontend (Flutter)

#### 1. 🎯 Error Handler Global
**Arquivo:** `lib/utils/error_handler.dart`

**Recursos:**
- Tratamento centralizado de exceções
- Suporte para Dio exceptions
- Retry automático com backoff exponencial
- UI amigável (dialogs e snackbars)

**Como usar:**
```dart
// Usando try-catch com ErrorHandler
try {
  await authService.login(email, password);
} on AppException catch (e) {
  e.log(); // Log estruturado
  context.showError(e.userMessage); // Mostra mensagem amigável
}

// Usando extension method (mais simples)
try {
  await api.fetchData();
} catch (e) {
  final appError = ErrorHandler.handleError(e, StackTrace.current);
  context.showErrorDialog('Erro', appError.userMessage);
}

// Retry automático
await ErrorHandler.retryWithBackoff(
  fn: () => api.fetchData(),
  maxRetries: 3,
  initialDelay: Duration(milliseconds: 500),
);
```

**Tipos de erro tratados:**
- Network errors (sem internet)
- Timeouts
- 401 Unauthorized (sessão expirada)
- 429 Rate Limit (muitas requisições)
- 5xx Server Errors
- Erros de parsing JSON

#### 2. ⚡ Cache Service Otimizado
**Arquivo:** `lib/services/cache_service.dart`

**Recursos:**
- Cache LRU com tamanho máximo (100 items)
- TTL configurável por item
- Invalidação por prefixo
- Statistics e monitoramento

**Como usar:**
```dart
// Cache singleton
final cache = CacheService();

// Set/Get básico
cache.set<List<Media>>('media_list', mediaList, ttl: Duration(minutes: 5));
final cached = cache.get<List<Media>>('media_list');

// Get ou Fetch (com fallback)
final media = await cache.getOrFetch<List<Media>>(
  'media_list',
  () => apiService.fetchMedia(),
  ttl: Duration(minutes: 5),
);

// Invalidar por prefixo
cache.removeByPrefix('media_'); // Remove todas as chaves que começam com 'media_'

// Extension method
'media_list'.setCached(mediaList);
final cached = 'media_list'.getCached<List<Media>>();

// API Manager com cache automático
final media = await ApiCacheManager.getWithCache<List<Media>>(
  ApiCacheManager.mediaListKey,
  () => api.fetchMedia(),
  ttl: Duration(minutes: 10),
);

// Invalidar cache de entidade
ApiCacheManager.invalidate('media'); // Remove cache_media_*
ApiCacheManager.invalidateAll();     // Limpa todo o cache de API
```

**Statistics:**
```dart
final stats = cache.getStats();
print('Tamanho: ${stats["size"]}');
print('Expirados: ${stats["expired"]}');
print('Idade média: ${stats["averageAgeMs"]}ms');
```

---

## 🔧 Checklist de Integração

### Backend

- [ ] **Aplicar migração de roles**
  ```bash
  psql -U postgres -d nexus -f backend/database/004_add_user_roles.sql
  ```

- [ ] **Atualizar dependências** (se usar logging em JSON)
  ```bash
  pip install python-json-logger
  ```

- [ ] **Testar validação de senha**
  ```bash
  curl -X POST http://localhost:8000/auth/register \
    -H "Content-Type: application/json" \
    -d '{
      "email": "user@example.com",
      "password": "weak"
    }'
  # Deve retornar 422 com mensagem de erro
  ```

- [ ] **Definir primeiros admin users**
  ```sql
  UPDATE users SET role = 'admin' WHERE email IN ('seu-email@example.com');
  ```

- [ ] **Testar CORS**
  ```bash
  curl -X OPTIONS http://localhost:8000/api/media \
    -H "Origin: https://untrusted.com"
  # Não deve incluir Access-Control headers se origin não permitida
  ```

### Frontend

- [ ] **Importar ErrorHandler em providers/services**
  ```dart
  import 'package:nexus_mobile/utils/error_handler.dart';
  ```

- [ ] **Usar ErrorHandler em try-catch**
  ```dart
  try {
    await service.doSomething();
  } catch (e, st) {
    final error = ErrorHandler.handleError(e, st);
    context.showError(error.userMessage);
  }
  ```

- [ ] **Implementar cache em media_service.dart**
  ```dart
  Future<List<Media>> fetchMedia() async {
    return await cache.getOrFetch<List<Media>>(
      'media_list',
      () => _fetchMediaFromAPI(),
      ttl: Duration(minutes: 5),
    );
  }
  ```

- [ ] **Testar offline mode**
  - Desabilitar internet
  - Cache deve servir dados antigos
  - Ao restaurar conexão, atualizar cache

---

## 📊 Monitoramento

### Backend - Logs JSON
```bash
# Ver logs em tempo real
tail -f /var/log/nexus/app.log | jq '.'

# Buscar erros
grep '"level":"ERROR"' /var/log/nexus/app.log

# Filtrar por request_id
grep 'request_id.*abc123' /var/log/nexus/app.log | jq '.'
```

### Frontend - Cache Statistics
```dart
// No main.dart ou em um provider para debugging
if (kDebugMode) {
  Timer.periodic(Duration(seconds: 10), (_) {
    final stats = CacheService().getStats();
    print('Cache Stats: $stats');
  });
}
```

---

## 🎯 Próximas Melhorias (Fase 2)

- [ ] **Compression & Caching**
  - [ ] Gzip compression em respostas FastAPI
  - [ ] ETags para validação
  - [ ] Cache-Control headers customizados

- [ ] **Testing**
  - [ ] Unit tests para ErrorHandler
  - [ ] Unit tests para CacheService
  - [ ] Integration tests para API

- [ ] **Performance**
  - [ ] CDN configuration
  - [ ] Image optimization
  - [ ] Database query optimization

---

## 📞 Suporte

Para dúvidas ou problemas:
1. Verificar logs em `/var/log/nexus/`
2. Revisar documentação em `ARCHITECTURE.md`
3. Testar endpoints com cURL ou Insomnia

