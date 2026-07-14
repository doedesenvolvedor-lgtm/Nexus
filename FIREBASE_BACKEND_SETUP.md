# Firebase Backend Setup - Instruções Completas

## 🔐 Obter Credenciais de Service Account (Backend)

### Passo 1: Firebase Console

1. Acesse https://console.firebase.google.com/
2. Projeto: **nexus-3fb82**
3. Clique na engrenagem (⚙️) → **Project Settings**

### Passo 2: Service Accounts

1. Navegue até a aba **Service Accounts**
2. Clique em **Generate New Private Key**
3. Um arquivo JSON será baixado

### Passo 3: Salvar no Backend

```bash
# Copie o arquivo JSON para o backend
cp ~/Downloads/nexus-3fb82-xxxxx.json /workspaces/Nexus/backend/firebase-credentials.json

# Ou se estiver no servidor
scp ~/Downloads/nexus-3fb82-xxxxx.json user@server:/path/to/nexus/backend/firebase-credentials.json
```

### Passo 4: Configurar .env

Edite `/workspaces/Nexus/backend/.env`:

```env
# ... suas outras variáveis ...

# Firebase Configuration
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
FIREBASE_PROJECT_ID=nexus-3fb82
FIREBASE_STORAGE_BUCKET=nexus-3fb82.firebasestorage.app
```

### Passo 5: Docker Compose

Se estiver usando Docker, adicione volume no `docker-compose.yml`:

```yaml
services:
  backend:
    image: nexus-backend
    volumes:
      - ./backend/firebase-credentials.json:/app/firebase-credentials.json:ro
    environment:
      - FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json
```

### Passo 6: Testar Conexão

```bash
# No diretório do backend
cd /workspaces/Nexus/backend

# Testar importação
python -c "from app.services.firebase_service import FirebaseService; f = FirebaseService(); print(f'Firebase OK: {f.is_initialized()}')"
```

---

## 📱 iOS - Configuração (Futuro)

Quando tiver as credenciais iOS do Firebase:

1. Baixe `GoogleService-Info.plist` do Firebase Console
2. Coloque em `nexus_mobile/ios/Runner/GoogleService-Info.plist`
3. Atualize `firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_IOS_API_KEY',
  appId: 'YOUR_IOS_APP_ID',
  messagingSenderId: '1035824903316',
  projectId: 'nexus-3fb82',
  storageBucket: 'nexus-3fb82.firebasestorage.app',
  iosBundleId: 'com.nexus.streaming',
);
```

---

## ✅ Verificação Final

### Checklist

```bash
# 1. Verificar arquivo de credenciais
ls -la /workspaces/Nexus/backend/firebase-credentials.json

# 2. Verificar requirements.txt
grep firebase-admin /workspaces/Nexus/backend/requirements.txt

# 3. Verificar models.py tem DeviceToken
grep "class DeviceToken" /workspaces/Nexus/backend/app/models.py

# 4. Verificar router notifications
grep "app.include_router(notifications" /workspaces/Nexus/backend/app/main.py

# 5. Verificar firebase_options.dart
grep -A 5 "static const FirebaseOptions android" /workspaces/Nexus/nexus_mobile/lib/firebase_options.dart

# 6. Verificar google-services.json
ls -la /workspaces/Nexus/nexus_mobile/android/app/google-services.json
```

Se todos os arquivos existem ✅, a configuração está completa!

---

## 🧪 Testar Notificações

### 1. Via Frontend

```dart
import 'package:nexus_mobile/services/notification_service.dart';

// No seu AuthProvider após login bem-sucedido:
final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('device_token');

if (token != null) {
  // Registrar no backend
  final response = await http.post(
    Uri.parse('http://localhost:8000/notifications/device-token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    },
    body: jsonEncode({
      'device_token': token,
      'device_type': Platform.isIOS ? 'ios' : 'android',
      'device_name': 'Test Device',
    }),
  );
  
  print('Registro de token: ${response.statusCode}');
}
```

### 2. Via Backend

```bash
# Enviar notificação de teste
curl -X POST http://localhost:8000/queue/push-notifications \
  -H "Content-Type: application/json" \
  -d '{
    "notifications": [
      {
        "user_id": "your-user-id",
        "title": "Test Notification",
        "body": "This is a test notification from Nexus!",
        "channel": "push"
      }
    ]
  }'
```

### 3. Monitorar Logs

```bash
# Terminal 1: Backend
cd /workspaces/Nexus/backend
python -m uvicorn app.main:app --reload

# Terminal 2: Worker
cd /workspaces/Nexus/backend
python -m workers.queue_worker

# Terminal 3: Logs
docker logs nexus-worker -f
```

---

## 🐛 Debug

### Firebase não inicializa

```python
# Teste manualmente
import firebase_admin
from firebase_admin import credentials, messaging
import os

cred_path = os.getenv('FIREBASE_CREDENTIALS_PATH')
print(f"Credenciais em: {cred_path}")

if not os.path.exists(cred_path):
    print("❌ Arquivo não encontrado!")
else:
    try:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase inicializado com sucesso!")
    except Exception as e:
        print(f"❌ Erro: {e}")
```

### Device token não registra

```bash
# Verificar no banco de dados
psql -U postgres -d nexus_db
SELECT * FROM device_tokens LIMIT 5;
\q
```

### Notificação não chega

```bash
# Verificar worker
docker logs nexus-worker --tail 50

# Verificar fila Redis
redis-cli
LLEN jobs:push_notifications
LRANGE jobs:push_notifications 0 -1
EXIT
```

---

## 📚 Referências

- [Firebase Admin SDK Python](https://firebase.google.com/docs/admin/setup)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Firebase](https://firebase.flutter.dev/)
