# Sistema de Trial de 3 Dias - App Mobile Nexus

## 📋 Visão Geral

Documentação completa do sistema de trial de 3 dias implementado no app mobile do Nexus em Flutter.

## ✨ Funcionalidades Implementadas

### 1. **Tela de Boas-vindas (`TrialWelcomeScreen`)**
Exibida logo após o registro do usuário:
- 🎉 Celebração visual com emojis
- ⭐ Badge destacado com "3 DIAS DE PREMIUM GRÁTIS"
- ✓ Lista de benefícios (filmes, séries, qualidade máxima, etc)
- ⏰ Data/hora de término do trial
- 🎬 Botão "COMEÇAR AGORA" para ir direto ao catálogo
- 💳 Botão "VER PLANOS" para explorar planos pagos

### 2. **Tela de Status (`TrialStatusScreen`)**
Permite acompanhar o trial em tempo real:
- ⏱️ **Contador Regressivo Circular**: Mostra horas, minutos e segundos
- 📊 **Informações de Dias, Horas, Minutos**: Em cards separados
- 📅 **Data de Término**: Formatada de forma clara
- 💰 **Catálogo de Planos**: Inline com opções de upgrade

### 3. **Tela de Planos (`PlansScreen`)**
Permite escolher e fazer upgrade para plano pago:
- **Planos Disponíveis**:
  - Free (grátis)
  - Basic (R$ 15/mês)
  - Standard (R$ 25/mês) - Marcado como Popular
  - Premium (R$ 40/mês)
- 📋 Lista detalhada de features de cada plano
- ✅ Seleção com radio button
- 💳 Integração pronta para Stripe/MercadoPago

### 4. **Notificações Automáticas (`TrialNotificationService`)**
Alertas automáticos em pontos críticos:
- **Dia 2**: "Seu trial termina amanhã!"
- **Último dia (2h antes)**: "Seu trial termina hoje às [hora]"
- **Na expiração**: "Seu trial expirou"
- ✅ Notificações agendadas com `flutter_local_notifications`
- 🔔 Suporte para Android e iOS

### 5. **Estado do Trial (`TrialProvider`)**
Gerenciam estado global:
```dart
- isTrialActive: bool
- daysRemaining: int
- trialEndsAt: DateTime?
- planType: String
- isLoading: bool
- errorMessage: String?
```

### 6. **Widgets Auxiliares**

#### **TrialBanner**
Banner compacto para exibir na tela home:
```dart
TrialBanner(
  onTap: () => Navigator.pushNamed(context, '/trial-status'),
)
```

#### **TrialUpgradeBottomSheet**
Bottom sheet para promoção rápida:
```dart
TrialUpgradeBottomSheet.show(context);
```

#### **TrialCheck**
Widget que verifica trial na inicialização e exibe welcome screen se necessário.

## 🔧 Instalação e Setup

### 1. Instalar Dependências

```bash
flutter pub get
```

Adicionadas automaticamente ao `pubspec.yaml`:
- `flutter_local_notifications: ^16.3.0`
- `intl: ^0.19.0`

### 2. Configurar Notificações Android

**android/app/build.gradle**:
```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21  // Necessário para local notifications
    }
}
```

**android/app/src/main/AndroidManifest.xml**:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### 3. Integrar no App

**lib/main.dart**:
```dart
import 'services/trial_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar notificações
  await TrialNotificationService.initialize();
  
  // ... resto do código
}
```

**lib/app/app.dart** (ou seu widget principal):
```dart
return MaterialApp(
  home: TrialCheck(
    child: const MyApp(),
    showWelcomeOnFirstTrial: true,
  ),
  // ...
);
```

## 📱 Exemplo de Uso Completo

### Exibir Banner na Home

```dart
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nexus')),
      body: Column(
        children: [
          // Trial Banner
          TrialBanner(
            onTap: () => Navigator.pushNamed(context, '/trial-status'),
          ),
          // Resto do conteúdo
          Expanded(
            child: ListView(
              children: [/* conteúdo */],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Carregar Status do Trial ao Abrir App

```dart
@override
void initState() {
  super.initState();
  _loadTrialStatus();
}

Future<void> _loadTrialStatus() async {
  final auth = context.read<AuthProvider>();
  final trial = context.read<TrialProvider>();
  
  if (auth.token != null) {
    await trial.loadTrialStatus(auth.token!);
    
    // Agendar notificações se em trial
    if (trial.isTrialActive && trial.trialEndsAt != null) {
      await TrialNotificationService.scheduleTrialNotifications(
        trial.trialEndsAt!,
      );
    }
  }
}
```

### Mostrar Bottom Sheet de Upgrade

```dart
ElevatedButton(
  onPressed: () => TrialUpgradeBottomSheet.show(context),
  child: const Text('Upgrade Agora'),
)
```

## 🔗 Integração com Backend

### AuthProvider Atualizado

Agora armazena token:
```dart
final authProvider = context.read<AuthProvider>();
await authProvider.login(email, token);

// Acessar token
print(authProvider.token);
```

### TrialService

Faz requisições ao backend:
```dart
final service = TrialService();

// Obter status do trial
final status = await service.getTrialStatus(token);

// Fazer upgrade
await service.upgradeToPlan(token, 'Premium');

// Verificar expiração
final result = await service.checkTrialExpiration(token);
```

## 📊 Endpoints Utilizados

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/subscriptions/me/trial-status` | GET | Status do trial com dias restantes |
| `/subscriptions/me` | GET | Detalhes da subscription |
| `/auth/me/profile` | GET | Perfil do usuário com subscription |
| `/subscriptions/upgrade-trial` | POST | Fazer upgrade para plano pago |
| `/subscriptions/check-trial-expiration` | POST | Verificar se trial expirou |

## 📁 Estrutura de Arquivos

```
lib/
├── providers/
│   ├── trial_provider.dart          # Gerenciamento de estado do trial
│   └── auth_provider.dart           # Atualizado com token
├── services/
│   ├── trial_service.dart           # Chamadas HTTP para trial
│   └── trial_notification_service.dart  # Notificações automáticas
├── screens/
│   └── trial/
│       ├── trial_welcome_screen.dart   # Tela de boas-vindas
│       ├── trial_status_screen.dart    # Tela de status com contador
│       └── plans_screen.dart           # Tela de planos
├── widgets/
│   ├── trial_check_widget.dart         # Verificação de trial no init
│   ├── trial_banner.dart               # Banner compacto
│   └── trial_upgrade_bottom_sheet.dart # Bottom sheet de upgrade
└── app/
    └── routes.dart                 # Rotas adicionadas
```

## 🎨 Customização

### Cores do Trial

Editar em cada arquivo de screen para mudar as cores (atualmente usando `Colors.purple`):

```dart
gradient: LinearGradient(
  colors: [
    Colors.purple.shade600,
    Colors.purple.shade800,
  ],
)
```

### Dias do Trial

Editado em `backend/app/routers/auth.py`:
```python
trial_ends_at = trial_started_at + timedelta(days=3)  # Mudar 3 para outro número
```

### Notificações

Editar mensagens em `lib/services/trial_notification_service.dart`:
```dart
await _notifications.zonedSchedule(
  1,
  '🎬 Seu trial termina amanhã!',  // Editar mensagem
  'Aproveite o último dia de acesso Premium ao Nexus.',
);
```

## 🚀 Próximas Etapas

- [ ] Integrar com Stripe/MercadoPago para pagamento
- [ ] Implementar deep links para compartilhar planos
- [ ] Analytics para rastrear conversões de trial para pago
- [ ] A/B testing de mensagens de notificação
- [ ] Dashboard admin para visualizar trials ativos
- [ ] Auto-renovação de planos

## 📝 Notas Importantes

1. **Permissões**: Certifique-se que o app tem permissão para enviar notificações
2. **Token Storage**: Token é salvo em `SharedPreferences` (usar alternativa mais segura em produção)
3. **Timezone**: Notificações usam timezone do dispositivo
4. **Testing**: Usar mock de data/hora para testar expiração

## 🐛 Troubleshooting

### Notificações não aparecem
- Verificar se `TrialNotificationService.initialize()` foi chamado no main
- Verificar permissões no `AndroidManifest.xml`
- Testar com hora do dispositivo alterada

### Trial não mostra na welcome screen
- Verificar se `TrialProvider.loadTrialStatus()` foi chamado com token válido
- Verificar resposta da API em `/subscriptions/me/trial-status`

### Contador regressivo não atualiza
- Verificar se `Timer` não foi cancelado
- Verificar se `DateTime` do backend está correto (com timezone UTC)

---

**Implementado em:** 2026-07-13  
**Status:** ✅ App Mobile concluído
