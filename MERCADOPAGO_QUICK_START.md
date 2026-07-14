# ⚡ Quick Setup - MercadoPago (5 minutos)

## 1️⃣ Criar Conta MercadoPago

1. Ir para: https://www.mercadopago.com.br/
2. Clique "Criar conta" (canto superior direito)
3. Escolher "Sou vendedor" ou "Sou desenvolvedor"
4. Completar cadastro com email e senha

## 2️⃣ Obter Credenciais

1. Após login, ir para: https://www.mercadopago.com.br/developers/panel/app
2. Clicar em "Criar aplicação"
3. Nome: "Nexus Streaming"
4. Após criar:
   - Copiar **Access Token** (começa com `APP_`)
   - Copiar **Client ID** (número grande)

## 3️⃣ Configurar Backend

### 3.1 Arquivo `.env`

```bash
cp .env.example .env
```

Editar `.env`:
```
MERCADOPAGO_ACCESS_TOKEN=APP_seu_token_aqui
MERCADOPAGO_CLIENT_ID=seu_client_id_aqui
WEBHOOK_URL=http://localhost:8000
```

### 3.2 Dependências

```bash
cd backend
pip install -r requirements.txt
```

### 3.3 Database

```bash
psql -U seu_usuario -d nexus_db -f database/002_add_trial_support.sql
```

## 4️⃣ Rodar Backend

```bash
cd backend
python -m uvicorn app.main:app --reload --port 8000
```

Deve aparecer:
```
Uvicorn running on http://127.0.0.1:8000
```

## 5️⃣ Testar Endpoint

```bash
# 1. Registrar usuário
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"teste@test.com",
    "username":"teste",
    "password":"123"
  }'

# Copiar token retornado
export TOKEN="eyJ0eXA..."

# 2. Criar checkout
curl -X POST http://localhost:8000/payments/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "Premium",
    "price": 39.99
  }'

# Deve retornar:
# {
#   "preference_id": "654321",
#   "payment_url": "https://www.mercadopago.com.br/checkout/v1/redirect?...",
#   "plan": "Premium"
# }
```

## 6️⃣ Testar Pagamento

1. Copiar `payment_url` da resposta anterior
2. Abrir no navegador (ou usar no app)
3. Fazer login no MercadoPago (ou criar conta teste)
4. Usar cartão de teste:
   - Número: **4111111111111111**
   - Mês/Ano: **11/25**
   - CVV: **123**
5. Clicar em "Pagar"

## 7️⃣ Configurar Flutter (opcional)

```bash
cd nexus_mobile
flutter pub get
flutter run
```

Plano agora abre MercadoPago dentro do app via WebView!

---

## 📊 Status

```
✅ Backend pronto
✅ Endpoints de pagamento
✅ Webhook configurado
✅ Flutter integrado
✅ Cartões de teste funcionando
```

## 🎉 Próximo Passo

**Integração com Webhook para produção:**
- [ ] Deploy em domínio com HTTPS
- [ ] Usar ngrok para webhook local: `ngrok http 8000`
- [ ] Adicionar URL webhook no MercadoPago

---

**Tempo total:** ~5 minutos ⏱️
