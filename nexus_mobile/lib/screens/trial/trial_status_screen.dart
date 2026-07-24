import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../providers/trial_provider.dart';

class TrialStatusScreen extends StatefulWidget {
  const TrialStatusScreen({super.key});

  @override
  State<TrialStatusScreen> createState() => _TrialStatusScreenState();
}

class _TrialStatusScreenState extends State<TrialStatusScreen> {
  Timer? _timer;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startCountdown();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final trialProvider = context.read<TrialProvider>();
      if (trialProvider.trialEndsAt != null) {
        final now = DateTime.now();
        final difference = trialProvider.trialEndsAt!.difference(now);

        if (difference.isNegative) {
          timer.cancel();
          _showTrialExpiredDialog();
        } else {
          setState(() {
            _hours = difference.inHours;
            _minutes = difference.inMinutes % 60;
            _seconds = difference.inSeconds % 60;
          });
        }
      }
    });
  }

  void _showTrialExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('😢 Trial Expirado'),
        content: const Text(
          'Seu período de teste gratuito terminou. Escolha um plano para continuar assistindo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Depois'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/plans');
            },
            child: const Text('Ver Planos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.purple.shade800,
        title: const Text('Status do Trial'),
        elevation: 0,
      ),
      body: Consumer<TrialProvider>(
        builder: (context, trialProvider, _) {
          if (trialProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!trialProvider.isTrialActive) {
            return _buildExpiredTrial(context);
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade600,
                            Colors.purple.shade800,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tempo restante',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoBox(label: 'Dias', value: trialProvider.daysRemaining.toString()),
                        _InfoBox(label: 'Horas', value: _hours.toString()),
                        _InfoBox(label: 'Minutos', value: _minutes.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (trialProvider.trialEndsAt != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '⏰ Seu trial termina em',
                            style: TextStyle(fontSize: 14, color: Colors.amber),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatDateTime(trialProvider.trialEndsAt!),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  const Text(
                    'Escolha seu plano',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _PlanCard(
                    name: 'Basic',
                    price: 'R\$ 15',
                    period: '/mês',
                    onTap: () => _upgradePlan(trialProvider, 'Basic'),
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    name: 'Standard',
                    price: 'R\$ 25',
                    period: '/mês',
                    onTap: () => _upgradePlan(trialProvider, 'Standard'),
                    isPopular: true,
                  ),
                  const SizedBox(height: 12),
                  _PlanCard(
                    name: 'Premium',
                    price: 'R\$ 40',
                    period: '/mês',
                    onTap: () => _upgradePlan(trialProvider, 'Premium'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _upgradePlan(dynamic provider, String plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Upgrade'),
        content: Text('Deseja fazer upgrade para o plano $plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upgrade para $plan iniciado...')),
      );
    }
  }

  String _formatDateTime(DateTime date) {
    final days = date.difference(DateTime.now()).inDays;
    final suffix = days == 0
        ? 'hoje'
        : days == 1
            ? 'amanhã'
            : 'em $days dias';
    return '$suffix às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildExpiredTrial(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('😢', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 20),
            const Text(
              'Seu Trial Expirou',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const Text(
              'Escolha um plano para continuar assistindo seus filmes e séries favoritos.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/plans'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: const Text('VER PLANOS', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  const _InfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.padLeft(2, '0'),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final VoidCallback onTap;
  final bool isPopular;
  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.onTap,
    this.isPopular = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isPopular ? Colors.purple : Colors.white.withValues(alpha: 0.2),
            width: isPopular ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isPopular ? Colors.purple.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (isPopular)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Chip(
                          label: Text('Popular', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.purple,
                          labelPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple)),
                      TextSpan(text: period, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
