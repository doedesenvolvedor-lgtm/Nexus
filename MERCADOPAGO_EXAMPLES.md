# 📝 Exemplos de Uso - MercadoPago Nexus

## 🔙 Backend - Python

### Exemplo 1: Criar Checkout no Backend

```python
from app.services.mercadopago_service import MercadoPagoService
from app.models import User, Payment
from sqlalchemy.orm import Session

def create_checkout(user: User, plan: str, price: float, db: Session):
    mp_service = MercadoPagoService()
    
    # Criar preferência
    preference = mp_service.create_preference(
        user_id=str(user.id),
        username=user.username,
        email=user.email,
        plan=plan,
        price=price,
    )
    
    # Registrar pagamento pendente
    payment = Payment(
        user_id=user.id,
        provider="mercadopago",
        payment_id=preference["preference_id"],
        amount=price,
        plan=plan,
        status="pending",
    )
    db.add(payment)
    db.commit()
    
    return preference["payment_url"]
```

### Exemplo 2: Processar Webhook

```python
from app.services.mercadopago_service import MercadoPagoService

async def process_webhook(webhook_data: dict, db: Session):
    mp_service = MercadoPagoService()
    
    if webhook_data.get("type") == "payment":
        payment_id = webhook_data.get("data", {}).get("id")
        
        # Obter status
        payment_info = mp_service.get_payment_status(str(payment_id))
        
        if payment_info["status"] == "approved":
            # Atualizar subscription
            user = db.query(User).filter(
                User.id == extract_user_id(payment_info)
            ).first()
            
            subscription = db.query(Subscription).filter(
                Subscription.user_id == user.id
            ).first()
            
            if subscription:
                subscription.plan_type = extract_plan(payment_info)
                subscription.status = "active"
                db.commit()
```

### Exemplo 3: Gerar Recibo

```python
def generate_receipt(payment_id: str) -> dict:
    mp_service = MercadoPagoService()
    payment_info = mp_service.get_payment_status(payment_id)
    
    receipt = {
        "payment_id": payment_info["id"],
        "amount": payment_info["amount"],
        "currency": payment_info["currency"],
        "status": payment_info["status"],
        "date": payment_info["date_approved"],
        "payer": payment_info["payer_email"],
    }
    
    return receipt
```

---

## 📱 Mobile - Dart/Flutter

### Exemplo 1: Fluxo Completo de Pagamento

```dart
// Assumindo que user está logado e tem token

class PaymentFlow {
  final AuthProvider authProvider;
  final MercadoPagoProvider mpProvider;
  
  Future<void> processPaymentFlow(String plan, double price) async {
    try {
      // 1. Criar checkout
      final paymentUrl = await mpProvider.createCheckout(
        token: authProvider.token!,
        plan: plan,
        price: price,
      );
      
      if (paymentUrl == null) {
        showError("Erro ao criar checkout: ${mpProvider.error}");
        return;
      }
      
      // 2. Abrir pagamento
      final success = await mpProvider.openPayment();
      
      if (!success) {
        showError("Erro ao abrir pagamento");
        return;
      }
      
      // 3. Aguardar confirmação (backend via webhook)
      // App receberá atualização via polling ou deep link
      
      // 4. Mostrar confirmação
      showSuccess("Pagamento realizado com sucesso!");
      
    } catch (e) {
      showError("Erro: $e");
    }
  }
}
```

### Exemplo 2: Widget de Checkout

```dart
class CheckoutButton extends StatefulWidget {
  final String plan;
  final double price;
  
  @override
  State<CheckoutButton> createState() => _CheckoutButtonState();
}

class _CheckoutButtonState extends State<CheckoutButton> {
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<MercadoPagoProvider>(
      builder: (context, mpProvider, child) {
        return ElevatedButton(
          onPressed: _isLoading ? null : _handlePayment,
          child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text("Pagar ${widget.plan} (R\$ ${widget.price})"),
        );
      },
    );
  }
  
  Future<void> _handlePayment() async {
    final authProvider = context.read<AuthProvider>();
    final mpProvider = context.read<MercadoPagoProvider>();
    
    setState(() => _isLoading = true);
    
    try {
      await mpProvider.createCheckout(
        token: authProvider.token!,
        plan: widget.plan,
        price: widget.price,
      );
      
      await mpProvider.openPayment();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
```

### Exemplo 3: Histórico de Pagamentos

```dart
class PaymentHistoryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final mpProvider = context.watch<MercadoPagoProvider>();
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: mpProvider.getPaymentHistory(
        token: authProvider.token!,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData) {
          return Center(child: Text("Nenhum pagamento"));
        }
        
        final payments = snapshot.data!["payments"] as List;
        
        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final payment = payments[index];
            return ListTile(
              title: Text("${payment['plan']} - R\$ ${payment['amount']}"),
              subtitle: Text(payment['status']),
              trailing: Text(payment['created_at']),
            );
          },
        );
      },
    );
  }
}
```

---

## 🔌 Integração Backend-Mobile

### Fluxo de Dados

```dart
// MOBILE: Iniciar pagamento
POST /payments/checkout
{
  "plan": "Premium",
  "price": 39.99
}

// BACKEND: Retorna
{
  "preference_id": "654321",
  "payment_url": "https://www.mercadopago.com.br/checkout/...",
  "plan": "Premium"
}

// MOBILE: Abre URL
url_launcher.openUrl(paymentUrl)

// USUARIO: Faz pagamento no MercadoPago

// MERCADOPAGO: Envia webhook ao backend
POST /webhook/mercadopago
{
  "type": "payment",
  "data": {
    "id": "12345678"
  }
}

// BACKEND: Atualiza banco de dados
UPDATE subscriptions 
SET plan_type='Premium', status='active'
WHERE user_id='...'

// MOBILE: Verifica status (próxima vez que abrir app ou polling)
GET /subscriptions/me/trial-status
// Recebe: "plan_type": "Premium"
```

---

## 🛠️ Exemplo de Configuração Completa

### .env Exemplo

```env
# MercadoPago
MERCADOPAGO_ACCESS_TOKEN=APP_1234567890_1234567890_1234567890
MERCADOPAGO_CLIENT_ID=1234567890
WEBHOOK_URL=https://seu-dominio.com

# Database
DATABASE_URL=postgresql://user:password@localhost:5432/nexus_db

# Auth
SECRET_KEY=sua-chave-secreta-super-segura-123
ALGORITHM=HS256

# API
API_URL=http://localhost:8000
FRONTEND_URL=http://localhost:3000
```

### main.py Setup Completo

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import payments, auth, subscriptions

app = FastAPI(title="Nexus API")

# CORS para mobile
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Ou domínio específico em prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
app.include_router(auth.router, prefix="/auth")
app.include_router(payments.router, prefix="/payments")
app.include_router(subscriptions.router, prefix="/subscriptions")

@app.get("/health")
def health():
    return {"status": "ok"}
```

---

## 📊 Exemplo de Relatório de Pagamentos

```python
from sqlalchemy.orm import Session
from app.models import Payment
from datetime import datetime, timedelta

def payment_report(db: Session, days: int = 30) -> dict:
    """Gerar relatório de pagamentos dos últimos N dias"""
    
    cutoff = datetime.utcnow() - timedelta(days=days)
    
    payments = db.query(Payment).filter(
        Payment.created_at >= cutoff,
        Payment.status == "approved",
    ).all()
    
    report = {
        "period": f"Últimos {days} dias",
        "total_payments": len(payments),
        "total_revenue": sum(p.amount for p in payments),
        "by_plan": {},
        "daily_average": 0,
    }
    
    # Agruprar por plano
    for payment in payments:
        plan = payment.plan
        if plan not in report["by_plan"]:
            report["by_plan"][plan] = {
                "count": 0,
                "revenue": 0,
                "average": 0,
            }
        report["by_plan"][plan]["count"] += 1
        report["by_plan"][plan]["revenue"] += payment.amount
    
    # Calcular médias
    report["daily_average"] = report["total_revenue"] / days
    
    for plan in report["by_plan"]:
        count = report["by_plan"][plan]["count"]
        revenue = report["by_plan"][plan]["revenue"]
        report["by_plan"][plan]["average"] = revenue / count if count > 0 else 0
    
    return report

# Usar:
report = payment_report(db, days=30)
print(f"Receita últimos 30 dias: R$ {report['total_revenue']:.2f}")
```

---

## 🎯 Exemplo de Tratamento de Erro

```dart
// No Provider
Future<String?> createCheckout({...}) async {
  try {
    final response = await http.post(...);
    
    if (response.statusCode == 401) {
      _error = "Sessão expirada. Faça login novamente.";
      notifyListeners();
      return null;
    }
    
    if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      _error = data['detail'] ?? 'Dados inválidos';
      notifyListeners();
      return null;
    }
    
    if (response.statusCode == 500) {
      _error = "Erro do servidor. Tente novamente.";
      notifyListeners();
      return null;
    }
    
    // ... resto do código
    
  } catch (e) {
    _error = "Erro de conexão: $e";
    notifyListeners();
    return null;
  }
}
```

---

## 🚀 Exemplo de Deploy em Produção

```bash
#!/bin/bash
# deploy.sh

# 1. Build backend
cd backend
pip install -r requirements.txt
gunicorn -w 4 -b 0.0.0.0:8000 app.main:app

# 2. Build mobile (release)
cd ../nexus_mobile
flutter build apk --release
# Output: build/app/outputs/apk/release/app-release.apk

# 3. Deploy Flutter para Play Store/App Store
flutter pub publish

# 4. Verificar webhook
curl https://seu-dominio.com/health
# {"status": "ok"}

# 5. Testar pagamento em produção
# Usar cartão real ou sandbox

echo "Deploy concluído!"
```

---

## 📞 Debugging

### Log de Pagamentos

```python
import logging

logger = logging.getLogger(__name__)

# Em mercadopago_service.py
try:
    response = requests.post(...)
    logger.info(f"Checkout criado: {preference['id']}")
except Exception as e:
    logger.error(f"Erro ao criar checkout: {e}")
```

### Debug Mobile

```dart
// Adicionar ao Provider
void _debugPrint(String message) {
  print("🔵 MercadoPago: $message");
  print("   URL: $_paymentUrl");
  print("   IsLoading: $_isLoading");
  print("   Error: $_error");
}
```

---

**Exemplos práticos prontos para usar!** 🎉
