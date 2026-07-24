import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mercadopago_provider.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String? _selectedPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade800,
        title: const Text('Escolha seu Plano'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Título
              const Text(
                'Planos Disponíveis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              const Text(
                'Escolha o plano que melhor se adequa a você',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Plano Free
              _buildPlanCard(
                name: 'Free',
                price: 'Grátis',
                period: '',
                features: const [
                  'Catálogo limitado',
                  'Qualidade padrão',
                  'Com anúncios',
                  '1 perfil',
                ],
                onSelect: () => _selectPlan('Free'),
                isSelected: _selectedPlan == 'Free',
                isPremium: false,
              ),

              const SizedBox(height: 20),

              // Plano Basic
              _buildPlanCard(
                name: 'Basic',
                price: 'R\$ 15',
                period: '/mês',
                features: const [
                  '✓ Todos os filmes',
                  '✓ Todas as séries',
                  '✓ HD (720p)',
                  '✓ 2 perfis',
                  '✓ Sem anúncios',
                ],
                onSelect: () => _selectPlan('Basic'),
                isSelected: _selectedPlan == 'Basic',
                isPremium: true,
              ),

              const SizedBox(height: 20),

              // Plano Standard
              _buildPlanCard(
                name: 'Standard',
                price: 'R\$ 25',
                period: '/mês',
                features: const [
                  '✓ Todos os filmes',
                  '✓ Todas as séries',
                  '✓ Full HD (1080p)',
                  '✓ 3 perfis',
                  '✓ Sem anúncios',
                  '✓ Downloads offline',
                ],
                onSelect: () => _selectPlan('Standard'),
                isSelected: _selectedPlan == 'Standard',
                isPremium: true,
                isPopular: true,
              ),

              const SizedBox(height: 20),

              // Plano Premium
              _buildPlanCard(
                name: 'Premium',
                price: 'R\$ 40',
                period: '/mês',
                features: const [
                  '✓ Todos os filmes',
                  '✓ Todas as séries',
                  '✓ 4K Ultra HD',
                  '✓ 4 perfis',
                  '✓ Sem anúncios',
                  '✓ Downloads offline',
                  '✓ Streaming simultâneo',
                ],
                onSelect: () => _selectPlan('Premium'),
                isSelected: _selectedPlan == 'Premium',
                isPremium: true,
              ),

              const SizedBox(height: 40),

              // Botão de confirmação
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedPlan != null && _selectedPlan != 'Free'
                      ? () => _confirmPlanSelection()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    disabledBackgroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedPlan == null
                        ? 'Selecione um plano'
                        : _selectedPlan == 'Free'
                            ? 'Continuar com plano Free'
                            : 'Confirmar $_selectedPlan',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão de cancelar
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Aviso sobre método de pagamento
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Você será redirecionado para o pagamento em seguida',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required VoidCallback onSelect,
    required bool isSelected,
    required bool isPremium,
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Colors.purple
                : isPopular
                    ? Colors.amber
                    : Colors.white.withValues(alpha: 0.2),
            width: isSelected || isPopular ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          color: isSelected
              ? Colors.purple.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isPopular)
                      const Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Chip(
                          label: Text(
                            '⭐ Popular',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.amber,
                          labelPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 0,
                          ),
                        ),
                      ),
                  ],
                ),
                // ignore: deprecated_member_use
                Radio<String>(
                  value: name,
                  // ignore: deprecated_member_use
                  groupValue: _selectedPlan,
                  // ignore: deprecated_member_use
                  onChanged: (value) => onSelect(),
                  activeColor: Colors.purple,
                  fillColor: WidgetStateProperty.all(Colors.purple),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Preço
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: price,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (period.isNotEmpty)
                    TextSpan(
                      text: period,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Features
            ...features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    const Text(
                      '✓',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _selectPlan(String plan) {
    setState(() {
      _selectedPlan = _selectedPlan == plan ? null : plan;
    });
  }

  void _confirmPlanSelection() {
    if (_selectedPlan == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Plano'),
        content: Text(
          'Você selecionou o plano $_selectedPlan.\n\nDeseja prosseguir com o pagamento?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processPayment();
            },
            child: const Text('Prosseguir'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedPlan == null || _selectedPlan == 'Free') return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final mpProvider = context.read<MercadoPagoProvider>();
    
    if (authProvider.token == null) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Erro: Token de autenticação não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Definir preço do plano
    double price = 0.0;
    switch (_selectedPlan) {
      case 'Basic':
        price = 15.00;
        break;
      case 'Standard':
        price = 25.00;
        break;
      case 'Premium':
        price = 40.00;
        break;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
        ),
      ),
    );

    try {
      // Criar checkout no backend
      final paymentUrl = await mpProvider.createCheckout(
        token: authProvider.token!,
        plan: _selectedPlan!,
        price: price,
      );

      if (!mounted) return;
      
      navigator.pop(); // Fechar loading

      if (paymentUrl != null) {
        // Abrir URL de pagamento do MercadoPago
        final success = await mpProvider.openPayment();
        if (!mounted) return;
        
        if (success) {
          // Pagamento iniciado, aguardar callback
          messenger.showSnackBar(
            SnackBar(
              content: Text('Abrindo pagamento para o plano $_selectedPlan...'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Erro ao abrir pagamento'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro: ${mpProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        navigator.pop(); // Fechar loading
        
        messenger.showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
