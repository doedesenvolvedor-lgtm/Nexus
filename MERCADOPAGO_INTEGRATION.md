# 💳 Guia Completo - MercadoPago Web Checkout

## 🎯 Visão Geral

Integração completa do **MercadoPago Web Checkout** no Nexus, permitindo pagamento de planos via MercadoPago.

**Fluxo:**
```
Usuário em Trial
      ↓
Seleciona Plano (Basic/Standard/Premium)
      ↓
App cria Checkout no Backend
      ↓
Backend gera Preferência no MercadoPago
      ↓
App abre URL de pagamento (browser)
      ↓
Usuário faz login e paga no MercadoPago
      ↓
Webhook do MercadoPago confirma pagamento
      ↓
Backend atualiza Subscription para "Premium"
      ↓
App volta e mostra confirmação
```

---

## 🔧 Setup Inicial

### 1. Criar Conta MercadoPago

1. Ir para: https://www.mercadopago.com.br/developers
2. Fazer login ou criar conta
3. Criar aplicação (integração)
4. Obter **Access Token** e **Client ID**

### 2. Configurar Backend

#### 2.1 Adicionar Variáveis de Ambiente

Criar `.env`:
```bash
MERCADOPAGO_ACCESS_TOKEN=YOUR_ACCESS_TOKEN_HERE
MERCADOPAGO_CLIENT_ID=YOUR_CLIENT_ID_HERE
WEBHOOK_URL=https://seu-dominio.com
# Ou para localhost:
WEBHOOK_URL=http://localhost:8000
```

#### 2.2 Instalar Dependências

```bash
cd backend
pip install -r requirements.txt
# Já adicionado:
# - mercado-pago
# - requests
# - httpx
```

#### 2.3 Aplicar Migration do Banco

```bash
psql -U seu_usuario -d nexus_db << 'EOF'
ALTER TABLE payments ADD COLUMN IF NOT EXISTS payment_id VARCHAR(255);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS plan VARCHAR(30);
ALTER TABLE payments ADD COLUMN IF NOT EXISTS metadata JSON;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP;
EOF
```

### 3. Configurar Mobile

#### 3.1 Adicionar Dependência

`pubspec.yaml` já tem:
```yaml
url_launcher: ^6.2.6
```

#### 3.2 Instalar Packages

```bash
cd nexus_mobile
flutter pub get
```

### 4. Configurar Webhook

MercadoPago envia notificações para:
```
POST https://seu-dominio.com/webhook/mercadopago
```

Configurar em:
1. https://www.mercadopago.com.br/developers/panel/app
2. Sua aplicação → Webhook
3. Adicionar URL: `https://seu-dominio.com/webhook/mercadopago`

---

## 🚀 Endpoints Backend

### 1. Criar Checkout

```http
POST /payments/checkout
Authorization: Bearer {token}
Content-Type: application/json

{
    "plan": "Premium",
    "price": 39.99
}
```

**Resposta:**
```json
{
    "preference_id": "654321",
    "payment_url": "https://www.mercadopago.com.br/checkout/v1/redirect?...",
    "plan": "Premium"
}
```

### 2. Callback de Sucesso

```http
GET /payments/success?preference_id=654321&payment_id=12345678&status=approved
```

Usuário é redirecionado automaticamente após pagamento.

### 3. Webhook de Notificação

```http
POST /webhook/mercadopago
Content-Type: application/json

{
    "type": "payment",
    "data": {
        "id": "12345678"
    }
}
```

### 4. Histórico de Pagamentos

```http
GET /payments/me/history?limit=10&offset=0
Authorization: Bearer {token}
```

**Resposta:**
```json
{
    "total": 2,
    "limit": 10,
    "offset": 0,
    "payments": [
        {
            "id": "uuid",
            "provider": "mercadopago",
            "amount": 39.99,
            "plan": "Premium",
            "status": "approved",
            "created_at": "2026-07-13T10:30:00"
        }
    ]
}
```

---

## 📱 Integração Mobile

### 1. FlutterService

`lib/services/mercadopago_service.dart`:

```dart
// Criar checkout
final paymentUrl = await MercadoPagoService.createCheckout(
  token: token,
  plan: 'Premium',
  price: 39.99,
);

// Abrir página de pagamento
await MercadoPagoService.openPaymentUrl(paymentUrl);

// Obter histórico
final history = await MercadoPagoService.getPaymentHistory(token: token);
```

### 2. Provider

`lib/providers/mercadopago_provider.dart`:

```dart
// Criar checkout
final url = await mpProvider.createCheckout(
  token: token,
  plan: 'Premium',
  price: 39.99,
);

// Abrir pagamento
await mpProvider.openPayment();

// Erros
print(mpProvider.error);

// Estado de carregamento
print(mpProvider.isLoading);
```

### 3. Tela de Planos Atualizada

`lib/screens/trial/plans_screen.dart`:

```dart
// Integração automática ao clicar "Confirmar"
final mpProvider = context.read<MercadoPagoProvider>();

// Criar checkout + abrir pagamento
await mpProvider.createCheckout(
  token: authProvider.token!,
  plan: 'Premium',
  price: 39.99,
);
await mpProvider.openPayment();
```

---

## 🧪 Testes

### Teste 1: Criar Checkout

```bash
curl -X POST http://localhost:8000/payments/checkout \
  -H "Authorization: Bearer seu-token" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "Premium",
    "price": 39.99
  }'

# Resposta:
# {
#   "preference_id": "654321",
#   "payment_url": "https://www.mercadopago.com.br/checkout/...",
#   "plan": "Premium"
# }
```

### Teste 2: Abrir Pagamento Localmente

1. Copiar `payment_url` da resposta anterior
2. Abrir em navegador
3. Fazer login no MercadoPago
4. Usar cartão de teste:

**Cartão de Teste (Débito):**
- Número: 4111111111111111
- Vencimento: 11/25
- CVV: 123
- Nome: Testuser

### Teste 3: Webhook Local com ngrok

```bash
# Instalar ngrok
brew install ngrok

# Rodar ngrok
ngrok http 8000

# Será gerado: https://xxxx-yyyy-zzz.ngrok.io
# Adicionar ao .env:
# WEBHOOK_URL=https://xxxx-yyyy-zzz.ngrok.io

# Configurar webhook no MercadoPago:
# https://xxxx-yyyy-zzz.ngrok.io/webhook/mercadopago
```

### Teste 4: Simular Webhook

```bash
curl -X POST http://localhost:8000/webhook/mercadopago \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment",
    "data": {
      "id": "12345678"
    }
  }'
```

---

## 💰 Planos e Preços

| Plano | Preço | Descrição |
|-------|-------|-----------|
| Free | Grátis | Catálogo limitado, com anúncios |
| Basic | R$ 15/mês | HD 720p, 2 perfis |
| Standard | R$ 25/mês | Full HD 1080p, 3 perfis, downloads |
| Premium | R$ 40/mês | 4K Ultra HD, 4 perfis, streaming simultâneo |
| Trial | Grátis (3 dias) | Acesso completo por 3 dias |

---

## 🔒 Segurança

### Validações

1. **Token JWT**: Todos os endpoints requerem autenticação
2. **External Reference**: Usado para verificar integridade
3. **Payment ID**: Validado no webhook
4. **Status**: Apenas "approved" ativa subscription

### Dados Sensíveis

- ❌ Nunca armazene dados de cartão no app
- ✅ MercadoPago gerencia tudo
- ✅ Dados criptografados em trânsito (HTTPS)

### CORS (se necessário)

```python
# app/main.py
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://seu-dominio.com"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## 📊 Rastreamento de Pagamentos

### Modelo Payment

```
payments (tabela)
├─ id (UUID)
├─ user_id (FK)
├─ provider (string: "mercadopago")
├─ payment_id (string: MP payment ID)
├─ amount (float: R$ 39.99)
├─ plan (string: "Premium")
├─ status (string: approved/rejected/pending)
├─ metadata (JSON: dados adicionais)
├─ created_at (timestamp)
└─ updated_at (timestamp)
```

### Consultar Pagamentos de um Usuário

```sql
SELECT * FROM payments 
WHERE user_id = 'seu-user-id' 
ORDER BY created_at DESC;
```

---

## 🐛 Troubleshooting

### Erro: "MERCADOPAGO_ACCESS_TOKEN não configurado"

**Causa:** Variável de ambiente não setada  
**Solução:**
```bash
# Verificar .env
cat .env | grep MERCADOPAGO

# Se vazio, adicionar:
MERCADOPAGO_ACCESS_TOKEN=seu_token_aqui
MERCADOPAGO_CLIENT_ID=seu_client_id_aqui
```

### Erro: "Erro ao criar preferência"

**Causa:** Token inválido ou expirado  
**Solução:**
1. Gerar novo token em https://www.mercadopago.com.br/developers/panel/app
2. Atualizar `.env`
3. Reiniciar backend: `python -m uvicorn app.main:app --reload`

### Erro: "Payment não encontrado no webhook"

**Causa:** Webhook chegou antes do pagamento ser registrado  
**Solução:** MercadoPago tentará novamente. Verificar logs:
```bash
# Logs do backend
tail -f app.log | grep "webhook"
```

### Erro: "URL de pagamento não abre no mobile"

**Causa:** `url_launcher` não configurado  
**Solução:**
```bash
# Android: AndroidManifest.xml já tem queries
# iOS: Adicionar ao Info.plist
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>https</string>
</array>

# Depois reinstalar
flutter clean
flutter pub get
flutter run
```

### Erro: "Preference_id no localStorage"

**Causa:** localStorage check no dashboard.html  
**Solução:** Não usar localStorage para preference_id (transitório)

---

## 📚 Referências Rápidas

### Comandos Backend

```bash
# Testar conexão MP
python -c "from app.services.mercadopago_service import MercadoPagoService; print(MercadoPagoService())"

# Ver logs
tail -f /var/log/nexus.log

# Reiniciar servidor
systemctl restart nexus-api
```

### Comandos Mobile

```bash
# Build APK para testes
flutter build apk --release

# Build AAB para Play Store
flutter build appbundle

# Test WebView (MercadoPago abre no WebView)
flutter run --profile
```

### URLs Úteis

- **Dashboard MP**: https://www.mercadopago.com.br/developers/panel
- **Docs MP**: https://www.mercadopago.com.br/developers/docs
- **Cartões Teste**: https://www.mercadopago.com.br/developers/pt/docs/checkout-pro/integration-test/test-cards
- **Webhook Status**: https://webhook.site (para testes)

---

## ✅ Checklist de Implementação

- [x] Backend service MercadoPago criado
- [x] Endpoints de pagamento implementados
- [x] Webhooks configurados
- [x] Modelo Payment aprimorado
- [x] Provider MercadoPago no Flutter
- [x] Serviço HTTP mercadopago_service.dart
- [x] Integração na tela de planos
- [x] URL launcher adicionado
- [x] Documentação completa

---

## 🚀 Próximas Etapas

1. **Configuração de Produção**
   - [ ] Usar API prod do MercadoPago (não sandbox)
   - [ ] SSL/HTTPS em domínio real
   - [ ] Configurar webhook em produção

2. **Melhorias**
   - [ ] Suporte a parcelamento (3x sem juros?)
   - [ ] Recibos por email
   - [ ] Histórico de transações no app
   - [ ] Cancelamento e reembolso

3. **Analytics**
   - [ ] Rastrear taxa de conversão
   - [ ] Monitorar abandono de checkout
   - [ ] Análise de planos mais vendidos

4. **Integração com Stripe** (opcional)
   - [ ] Adicionar suporte a Stripe também
   - [ ] Usuário escolhe método de pagamento

---

## 📞 Suporte

- **Docs MercadoPago**: https://www.mercadopago.com.br/developers/docs/checkout-pro/integration-test
- **Issues de integração**: https://www.mercadopago.com.br/developers/es/support
- **Email suporte MP**: developers@mercadopago.com

---

**Data:** 2026-07-13  
**Status:** ✅ Implementado  
**Versão:** 1.0.0
