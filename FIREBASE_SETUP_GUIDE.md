# Firebase Cloud Messaging - Configuração Completa

## 📱 Android - Configuração Realizada

### ✅ Credenciais Android Adicionadas

O arquivo `firebase_options.dart` foi atualizado com as seguintes credenciais:
- **Project ID**: `nexus-3fb82`
- **API Key**: `AIzaSyCQ9w1DVEtELR9SAqmTnMO5jR1b97L6nNk`
- **App ID**: `1:1035824903316:android:5dad8f7c8da2ccfa75f081`
- **Messaging Sender ID**: `1035824903316`
- **Storage Bucket**: `nexus-3fb82.firebasestorage.app`

### ✅ google-services.json Criado

O arquivo `android/app/google-services.json` foi criado automaticamente.

**Arquivos atualizados:**
```
nexus_mobile/
├── lib/firebase_options.dart  ✅ Credenciais Android
├── android/app/google-services.json  ✅ Criado
└── pubspec.yaml  ✅ Dependências adicionadas
```

### 📋 Próximos Passos - Android

1. **No Terminal (IDE Android Studio ou VS Code):**
```bash
cd nexus_mobile
flutter pub get
flutter pub upgrade firebase_messaging firebase_analytics firebase_crashlytics
```

2. **Build do Android (Teste):**
```bash
flutter build apk --debug
# ou
flutter build appbundle
```

3. **Se tiver erro de compilação:**
   - Verifique se tem Java 11+ instalado: `java -version`
   - Verifique Android SDK: `flutter doctor -v`
   - Limpe build: `flutter clean && flutter pub get`

---

## 🔧 Backend (Python/FastAPI) - Configuração

### 1️⃣ Obter Credenciais de Service Account

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. Projeto: **nexus-3fb82**
3. Clique na engrenagem (⚙️) → **Project Settings**
4. Aba **Service Accounts**
5. Clique em **Generate New Private Key**
6. Salve o arquivo JSON

### 2️⃣ Copiar Arquivo para Backend

```bash
# De seu computador local
scp firebase-credentials.json user@server:/path/to/nexus/backend/

# OU se estiver localmente
cp firebase-credentials.json /workspaces/Nexus/backend/firebase-credentials.json
```

### 3️⃣ Configurar .env

Adicione ao `.env` do backend:
```env
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
FIREBASE_PROJECT_ID=nexus-3fb82
FIREBASE_STORAGE_BUCKET=nexus-3fb82.firebasestorage.app
```

### 4️⃣ Atualizar requirements.txt

```bash
cd /workspaces/Nexus/backend
pip install -r requirements.txt
```

### 5️⃣ Testar Integração

```python
from app.services.firebase_service import FirebaseService

firebase = FirebaseService()
print(f"Firebase Initialized: {firebase.is_initialized()}")
```

---

## 📊 Endpoints de Notificações

### 1. Registrar Device Token

**Quando usuário faz login:**
```bash
POST /notifications/device-token

{
  "device_token": "cTvHu7_xRg:APA91bFa...",
  "device_type": "android",
  "device_name": "Samsung Galaxy S21"
}
```

### 2. Listar Device Tokens do Usuário

```bash
GET /notifications/device-tokens
```

**Resposta:**
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "device_token": "cTvHu7_xRg:APA91bFa...",
    "device_type": "android",
    "device_name": "Samsung Galaxy S21",
    "is_active": true
  }
]
```

### 3. Remover Device Token

```bash
DELETE /notifications/device-token/{token_id}
```

### 4. Remover Todos os Tokens

```bash
DELETE /notifications/device-token
```

---

## 📲 Enviar Notificações via Fila

### Admin envia notificação para múltiplos usuários

```bash
curl -X POST http://localhost:8000/queue/push-notifications \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "notifications": [
      {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Novo Episódio Disponível",
        "body": "Série Incrível - Episódio 5 já está disponível!",
        "channel": "push"
      },
      {
        "user_id": "660e8400-e29b-41d4-a716-446655440001",
        "title": "Assinatura Ativada",
        "body": "Seu plano Premium foi ativado!",
        "channel": "push"
      }
    ]
  }'
```

---

## 🔍 Monitorar Notificações

### Firebase Console - Cloud Messaging

1. Acesse [Firebase Console](https://console.firebase.google.com/)
2. nexus-3fb82 → **Messaging**
3. Veja estatísticas de entrega

### Logs do Worker

```bash
# Docker
docker logs nexus-worker -f

# Local
python -m workers.queue_worker
```

### Banco de Dados

```sql
-- Verificar device tokens registrados
SELECT * FROM device_tokens WHERE is_active = true;

-- Verificar histórico de jobs de push
SELECT * FROM queue_jobs WHERE job_type = 'push_notifications_batch' ORDER BY created_at DESC LIMIT 10;
```

---

## ✅ Checklist de Configuração

### Mobile (Android)
- [x] `firebase_options.dart` com credenciais Android
- [x] `android/app/google-services.json` criado
- [x] Dependências adicionadas ao `pubspec.yaml`
- [ ] Build e teste no emulador/dispositivo
- [ ] Verificar permissões no AndroidManifest.xml

### Backend
- [ ] Arquivo `firebase-credentials.json` copiado
- [ ] `.env` configurado com `FIREBASE_CREDENTIALS_PATH`
- [ ] Dependência `firebase-admin` instalada
- [ ] Migration SQL executada (`003_add_device_tokens.sql`)
- [ ] Testar endpoints de notificação

### Fluxo Completo
- [ ] Usuário faz login → device token registrado
- [ ] Admin envia notificação → job enfileirado
- [ ] Worker processa → Firebase Cloud Messaging
- [ ] Celular recebe → notificação exibida
- [ ] Analytics registra evento
- [ ] Crashlytics monitora erros

---

## 🐛 Troubleshooting

### "Firebase não está inicializado"
```
✓ Verifique FIREBASE_CREDENTIALS_PATH
✓ Verifique se arquivo JSON existe
✓ Verifique permissões do arquivo
```

### "Device token não registrado"
```
✓ Verifique se NotificationService().initialize() foi chamado
✓ Verifique permissões do app (POST /notifications/device-token)
✓ Verifique log do mobile: adb logcat | grep firebase
```

### "Notificação não chega"
```
✓ Verifique se device_token está ativo em DB
✓ Verifique logs do worker
✓ Verifique Firebase Cloud Messaging status
✓ Teste manualmente via Firebase Console → Send Test Message
```

### Analytics não mostra dados
```
✓ Aguarde alguns minutos (delay de propagação)
✓ Verifique se coleta está habilitada
✓ Compile app em modo Release para Crashlytics
```

---

## 📞 Suporte

Para mais informações:
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Firebase](https://firebase.flutter.dev/)
- [Cloud Messaging API](https://developers.google.com/cloud-messaging)
