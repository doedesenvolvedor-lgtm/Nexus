import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/trial_provider.dart';
import '../../providers/auth_provider.dart';

class TrialWelcomeScreen extends StatefulWidget {
  const TrialWelcomeScreen({super.key});

  @override
  State<TrialWelcomeScreen> createState() => _TrialWelcomeScreenState();
}

class _TrialWelcomeScreenState extends State<TrialWelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadTrialInfo();
  }

  Future<void> _loadTrialInfo() async {
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token; // Você precisa adicionar isso em AuthProvider

    if (token != null) {
      final trialProvider = context.read<TrialProvider>();
      await trialProvider.loadTrialStatus(token);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TrialProvider>(
        builder: (context, trialProvider, _) {
          if (trialProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.purple.shade800,
                    Colors.purple.shade900,
                    Colors.black87,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),

                      // Emoji celebração
                      const Text(
                        '🎉',
                        style: TextStyle(fontSize: 100),
                      ),

                      const SizedBox(height: 24),

                      // Título
                      const Text(
                        'Bem-vindo ao Nexus!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Subtítulo
                      const Text(
                        'Você ganhou',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Badge de 3 dias Premium
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade600,
                              Colors.amber.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '⭐ 3 DIAS DE PREMIUM GRÁTIS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Dias restantes: ${trialProvider.daysRemaining}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Benefícios
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Column(
                          children: [
                            _BenefitRow(
                              icon: '✓',
                              text: 'Todos os filmes',
                            ),
                            SizedBox(height: 12),
                            _BenefitRow(
                              icon: '✓',
                              text: 'Todas as séries',
                            ),
                            SizedBox(height: 12),
                            _BenefitRow(
                              icon: '✓',
                              text: 'Qualidade máxima',
                            ),
                            SizedBox(height: 12),
                            _BenefitRow(
                              icon: '✓',
                              text: 'Sem anúncios',
                            ),
                            SizedBox(height: 12),
                            _BenefitRow(
                              icon: '✓',
                              text: 'Até 4 perfis',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Data de expiração
                      if (trialProvider.trialEndsAt != null)
                        Text(
                          'Seu teste termina em:\n${_formatDate(trialProvider.trialEndsAt!)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 32),

                      // Botão principal
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacementNamed('/home');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'COMEÇAR AGORA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Botão secundário
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/plans');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Colors.purple,
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'VER PLANOS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _BenefitRow extends StatelessWidget {
  final String icon;
  final String text;

  const _BenefitRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          icon,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
