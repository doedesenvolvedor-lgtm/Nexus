# 🔧 Setup Mercado Pago - Assinaturas (Guia Prático)

## 📋 Resumo do Fluxo

```
Usuário aciona pagamento
    ↓
Seu app chama: POST /payments/checkout
    ↓
Backend cria preferência no MP
    ↓
Usuário redireciona para MP
    ↓
Usuário paga (sem você ver número cartão)
    ↓
MP chama seu webhook: /payments/webhook
    ↓
Backend atualiza assinatura no BD
    ↓
Usuário vira Premium ✅
```

---

## ✅ PASSO 1: Credenciais do Mercado Pago

### 1.1 Criar Conta

1. Acesse: https://www.mercadopago.com.br/
2. Clique em **"Criar conta"** (canto superior direito)
3. Escolha **"Sou desenvolvedor"**
4. Complete o cadastro

### 1.2 Obter Credenciais

1. Após login, vá para: https://www.mercadopago.com.br/developers/panel/app
2. Clique em **"Criar aplicação"**
3. Nome: `Nexus Streaming`
4. Após criar, você receberá:

```
Access Token:  APP_xxxxxxxxxxxxx
Client ID:     1234567890
Public Key:    APP_xxxxxxxxxxxx
```

**⚠️ IMPORTANTE:** Copie e guarde esses valores com segurança!

---

## 🔐 PASSO 2: Configurar Variáveis de Ambiente

### 2.1 Editar `.env`

```bash
# Abrir arquivo
nano /workspaces/Nexus/backend/.env
```

### 2.2 Adicionar (ou atualizar):

```bash
# ===== MercadoPago =====
MERCADOPAGO_ACCESS_TOKEN=APP_seu_access_token_aqui
MERCADOPAGO_CLIENT_ID=seu_client_id_aqui
MERCADOPAGO_PUBLIC_KEY=APP_seu_public_key_aqui

# URL onde o MP chamará seu webhook
WEBHOOK_URL=http://localhost:8000
# Em produção: https://api.nexusstream.com
```

### 2.3 Verificar `.env.example`

```bash
cat /workspaces/Nexus/backend/.env.example | grep -A 3 "MercadoPago"
```

---

## 🚀 PASSO 3: Backend Já Está Pronto!

Seu backend já tem:

✅ **Serviço MercadoPago** (`app/services/mercadopago_service.py`)
- `create_preference()` → Cria checkout
- `get_payment_status()` → Verifica status
- `process_webhook()` → Processa webhook

✅ **Endpoints** (`app/routers/payments.py`)
- `POST /payments/checkout` → Inicia pagamento
- `GET /payments/success` → Retorno após MP
- `POST /payments/webhook` → Webhook do MP

✅ **Database**
- Tabela `Payment` com todos os campos
- Tabela `Subscription` para controlar planos

---

## 📱 PASSO 4: Testar (Local)

### 4.1 Iniciar Backend

```bash
cd /workspaces/Nexus/backend
pip install -r requirements.txt  # Se não tiver feito
python -m uvicorn app.main:app --reload --port 8000
```

Deve aparecer:
```
Uvicorn running on http://127.0.0.1:8000
```

### 4.2 Registrar Usuário Teste

```bash
curl -X POST http://localhost:8000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email":"teste@test.com",
    "username":"teste",
    "password":"123456"
  }'

# Copiar o token retornado
export TOKEN="eyJ0eXA..."
```

### 4.3 Criar Checkout

```bash
curl -X POST http://localhost:8000/payments/checkout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "plan": "Premium",
    "price": 39.99
  }'
```

**Resposta esperada:**
```json
{
  "preference_id": "654321",
  "payment_url": "https://www.mercadopago.com.br/checkout/v1/redirect?...",
  "plan": "Premium"
}
```

### 4.4 Testar Pagamento

1. Copie a URL de `payment_url`
2. Abra no navegador: `http://localhost:3000` (seu app)
3. Faça login com `teste@test.com`
4. Clique em "Assinar Premium"
5. Será redirecionado ao Mercado Pago
6. Use cartão de teste:
   - **Número:** `4111111111111111`
   - **Mês/Ano:** `11/25`
   - **CVV:** `123`
   - **Nome:** Qualquer nome
7. Clique "Pagar"

✅ Se tudo OK, você voltará ao seu app!

---

## 🔗 PASSO 5: Webhook (Assinaturas)

O webhook é essencial para atualizar assinaturas quando o pagamento é aprovado.

### 5.1 Configurar Webhook no Mercado Pago

1. Vá para: https://www.mercadopago.com.br/developers/panel/notifications
2. Na seção **"Webhooks"**, clique em **"Adicionar notificação"**
3. Configure:

```
URL: https://api.nexusstream.com/payments/webhook
```

4. Selecione eventos:
   - ✅ `payment.created`
   - ✅ `payment.updated`

5. Salve

### 5.2 Como Funciona (Backend)

Quando um pagamento é aprovado no MP, ele chama seu webhook:

```
POST /payments/webhook
{
  "type": "payment",
  "action": "payment.updated",
  "data": {
    "id": "payment_id_do_mp"
  }
}
```

Seu backend então:

1. ✅ Obtém detalhes do pagamento via API do MP
2. ✅ Verifica se o status é "approved"
3. ✅ Atualiza a assinatura do usuário no BD
4. ✅ Envia email de confirmação

**O código já está pronto em `app/services/mercadopago_service.py`!**

---

## 🔒 Segurança - Importante!

### ❌ O que NÃO fazer:

```python
# ❌ NUNCA fazer isso:
numero_cartao = request.json["numero_cartao"]  # Ilegal! PCI DSS
```

### ✅ O que fazer (já implementado):

```python
# ✅ Correto:
# 1. Frontend envia token seguro (checkout.js do MP)
# 2. Seu backend NUNCA vê número completo do cartão
# 3. MP processa o pagamento de forma segura
# 4. Backend recebe apenas confirmação via webhook
```

---

## 📊 PASSO 6: Testar Webhook (Local)

Para testar webhook em desenvolvimento, use:

### 6.1 Instalar Ngrok (expor localhost)

```bash
# Baixar ngrok
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok-v3-stable-linux-x86_64.zip -o ngrok.zip
unzip ngrok.zip
sudo mv ngrok /usr/local/bin/

# Ou via apt (Ubuntu):
sudo apt install ngrok
```

### 6.2 Expor Seu Backend

```bash
# Terminal 1: Backend rodando
cd /workspaces/Nexus/backend
python -m uvicorn app.main:app --reload --port 8000

# Terminal 2: Expor com ngrok
ngrok http 8000
```

Você receberá:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:8000
```

### 6.3 Atualizar `.env` Temporariamente

```bash
WEBHOOK_URL=https://abc123.ngrok.io
```

### 6.4 Testar Webhook Manualmente

```bash
curl -X POST https://abc123.ngrok.io/payments/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment",
    "data": {
      "id": "12345"
    }
  }'
```

Deve retornar: `{"status": "success"}`

---

## 🚀 PASSO 7: Deploy em Produção

### 7.1 Atualizar `.env` na VPS

```bash
# SSH para VPS
ssh root@seu-ip-vps

# Editar .env
nano /opt/nexus/backend/.env
```

```bash
MERCADOPAGO_ACCESS_TOKEN=APP_token_producao
MERCADOPAGO_CLIENT_ID=seu_client_id
MERCADOPAGO_PUBLIC_KEY=APP_public_key_producao
WEBHOOK_URL=https://api.nexusstream.com
```

### 7.2 Reiniciar Backend

```bash
cd /opt/nexus
docker-compose restart backend
```

### 7.3 Testar Webhook na VPS

```bash
# No Mercado Pago, enviar webhook de teste
# Ele chamará: https://api.nexusstream.com/payments/webhook

# Ou manualmente:
curl -X POST https://api.nexusstream.com/payments/webhook \
  -H "Content-Type: application/json" \
  -d '{"type": "payment", "data": {"id": "12345"}}'
```

---

## ✅ Checklist de Implementação

- [ ] **1. Credenciais**
  - [ ] Conta Mercado Pago criada
  - [ ] Access Token copiado
  - [ ] Client ID copiado
  - [ ] Public Key copiado

- [ ] **2. Configuração**
  - [ ] `.env` atualizado com credenciais
  - [ ] Backend testado localmente
  - [ ] Endpoints `/payments/checkout` funcionando

- [ ] **3. Teste de Pagamento**
  - [ ] Usuário criado
  - [ ] Checkout iniciado
  - [ ] Redireção ao Mercado Pago OK
  - [ ] Pagamento com cartão de teste OK
  - [ ] Retorno ao app OK

- [ ] **4. Webhook**
  - [ ] Webhook configurado no MP
  - [ ] Assinatura atualizada após pagamento
  - [ ] Email de confirmação enviado

- [ ] **5. Produção**
  - [ ] `.env` atualizado na VPS
  - [ ] Webhook URL apontando para domínio
  - [ ] Primeira transação real testada
  - [ ] Monitoramento ativo

---

## 🆘 Troubleshooting

### Erro: "MERCADOPAGO_ACCESS_TOKEN não configurado"

```bash
# Verificar .env
cat /workspaces/Nexus/backend/.env | grep MERCADOPAGO

# Se vazio, adicionar:
echo 'MERCADOPAGO_ACCESS_TOKEN=APP_seu_token' >> .env
```

### Webhook não está sendo chamado

1. Verificar se MP consegue conectar:
   - Em https://www.mercadopago.com.br/developers/panel/notifications
   - Clique na seta ao lado do webhook
   - Veja logs de tentativas

2. Se usar ngrok, certificar que está rodando:
   ```bash
   ngrok http 8000
   ```

3. Verificar logs do backend:
   ```bash
   docker-compose logs -f backend
   ```

### Erro "Invalid Access Token"

- Verificar se token começa com `APP_`
- Copiar novamente em: https://www.mercadopago.com.br/developers/panel/app
- Reiniciar backend

---

## 📚 Documentos Relacionados

- [MERCADOPAGO_INTEGRATION.md](MERCADOPAGO_INTEGRATION.md) - Integração completa
- [MERCADOPAGO_EXAMPLES.md](MERCADOPAGO_EXAMPLES.md) - Exemplos de código
- [MERCADOPAGO_SUMMARY.md](MERCADOPAGO_SUMMARY.md) - Resumo da implementação
- [backend/app/services/mercadopago_service.py](backend/app/services/mercadopago_service.py) - Código do serviço
- [backend/app/routers/payments.py](backend/app/routers/payments.py) - Endpoints

---

## 🎯 Próximos Passos

1. ✅ Seguir este guia até a seção "✅ Checklist de Implementação"
2. ✅ Testar pagamento com cartão de teste
3. ✅ Configurar alertas de erro
4. ✅ Treinar equipe sobre o fluxo
5. ✅ Monitorar transações em produção

---

**Status:** 🟢 Pronto para deploy!

Qualquer dúvida, consulte os arquivos relacionados listados acima.
