"""
Exemplo de como usar o Firebase Cloud Messaging no backend

1. Configuração do Firebase
================================

Baixe seu arquivo de credenciais JSON do Firebase Console e salve como:
/workspaces/Nexus/backend/firebase-credentials.json

Adicione ao arquivo .env:
FIREBASE_CREDENTIALS_PATH=/app/firebase-credentials.json

2. Endpoints de Device Tokens
================================

POST /notifications/device-token
  - Registra um novo device token para o usuário autenticado
  - Requer: device_token, device_type (ios/android)
  - Retorna: {"message": "Device token registrado com sucesso", "id": "..."}

GET /notifications/device-tokens
  - Lista todos os device tokens ativos do usuário
  - Requer: autenticação
  - Retorna: lista de device tokens

DELETE /notifications/device-token/{token_id}
  - Remove um device token específico
  - Requer: autenticação, token_id válido
  - Retorna: {"message": "Device token removido"}

DELETE /notifications/device-token
  - Remove todos os device tokens do usuário
  - Requer: autenticação
  - Retorna: {"message": "Todos os device tokens foram removidos"}

3. Enviando Notificações via Admin
================================

Exemplo usando curl:

# Enviar notificação para múltiplos usuários
curl -X POST http://localhost:8000/queue/push-notifications \\
  -H "Content-Type: application/json" \\
  -d '{
    "notifications": [
      {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Novo conteúdo disponível",
        "body": "Assista agora: Série Incrível Episódio 5",
        "channel": "push"
      },
      {
        "user_id": "660e8400-e29b-41d4-a716-446655440001",
        "title": "Sua assinatura foi ativada",
        "body": "Aproveite o acesso premium!",
        "channel": "push"
      }
    ]
  }'

Exemplo em Python:

import requests

notifications = [
    {
        "user_id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Novo conteúdo disponível",
        "body": "Assista agora: Série Incrível Episódio 5",
        "channel": "push"
    }
]

response = requests.post(
    "http://localhost:8000/queue/push-notifications",
    json={"notifications": notifications}
)

print(response.json())

4. Fluxo de Notificações
================================

Celular com app instalado:
  ↓
  [NotificationService.initialize() - obtém device token]
  ↓
  [Usuário faz login]
  ↓
  [AuthProvider registra device_token no backend]
  ↓
  Backend salva em PostgreSQL (tabela device_tokens)
  ↓
  
Quando admin envia notificação:
  ↓
  Painel Admin / API → POST /queue/push-notifications
  ↓
  Backend → enfileira job em Redis (PUSH_QUEUE)
  ↓
  Queue Worker → processa batch
  ↓
  process_push_batch() busca device_tokens do usuário
  ↓
  Firebase Service → send_multicast() para todos os tokens
  ↓
  Firebase Cloud Messaging → envia via APNs (iOS) ou GCM (Android)
  ↓
  Celular recebe notificação
  ↓
  NotificationService._showLocalNotification() exibe para usuário

5. Analytics
================================

O Firebase Analytics é inicializado automaticamente no NotificationService.

Exemplos de eventos que são rastreados automaticamente:
- session_start: quando o app é aberto
- session_end: quando o app é fechado
- notification_received_foreground: quando uma notificação é recebida em primeiro plano
- notification_opened: quando o usuário clica na notificação

Exemplo de evento customizado no seu código:

NotificationService().logEvent(
    name: 'video_started',
    parameters: {
        'video_id': '123',
        'category': 'series',
        'duration': '45m',
    }
)

Acompanhe no Firebase Console → Analytics → Events

6. Crashlytics
================================

O Firebase Crashlytics é inicializado automaticamente.

Erros são automaticamente capturados:
- Exceções não tratadas
- Erros da plataforma (iOS/Android)
- Travamentos do app

Para reportar erro manualmente:

try {
    // código que pode falhar
} catch (e, stackTrace) {
    NotificationService().recordException(e, stackTrace);
}

Para adicionar contexto adicional:

NotificationService().setCrashlyticsCustomKey('user_plan', 'premium');
NotificationService().setCrashlyticsCustomKey('video_id', '12345');

Acompanhe no Firebase Console → Crashlytics → Issues

7. Estrutura de Dados
================================

Tabela device_tokens:
- id: UUID (chave primária)
- user_id: UUID (referencia users)
- device_token: string (token único do Firebase)
- device_type: string (ios ou android)
- device_name: string (opcional, nome do dispositivo)
- is_active: boolean (ativo/inativo)
- created_at: timestamp (quando foi registrado)
- updated_at: timestamp (última atualização)
- last_used_at: timestamp (última notificação recebida)

8. Dicas e Troubleshooting
================================

Se as notificações não chegam:
1. Verifique se FIREBASE_CREDENTIALS_PATH está configurado
2. Verifique se o arquivo JSON de credenciais existe
3. Verifique se o device_token foi registrado no backend
4. Verifique os logs do worker: docker logs nexus-worker
5. Teste manualmente enviando uma notificação simples

Se o device_token não é registrado:
1. Verifique se o NotificationService foi inicializado
2. Verifique os logs do mobile: adb logcat | grep firebase
3. Verifique se o endpoint POST /notifications/device-token foi chamado
4. Verifique as credenciais (token de acesso JWT)

Se Analytics não funciona:
1. Verifique se Google Analytics está ativado no Firebase Console
2. Verifique se a coleta de dados está habilitada no app
3. Espere alguns minutos para os dados aparecerem no Console (há delay)

Se Crashlytics não funciona:
1. Verifique se o app foi compilado em modo Release
2. Verifique os logs no Console
3. Force um crash para teste (remova um assert)
"""
