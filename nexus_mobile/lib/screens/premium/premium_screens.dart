import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_widgets.dart';

/// Tela de Boas-vindas ao Trial (3 dias grátis)
class TrialWelcomeScreen extends StatelessWidget {
  const TrialWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                
                // Celebração Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '🎉',
                      style: GoogleFonts.poppins(fontSize: 60),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Welcome Text
                Text(
                  'Bem-vindo ao\nNexustwos!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Trial Duration
                Text(
                  'Você ganhou',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Big Trial Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '⭐ 3 DIAS DE PREMIUM GRÁTIS ⭐',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Benefits Section
                Text(
                  'Aproveite acesso completo durante o período de teste',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Benefits List
                ...[
                  'Filmes ilimitados',
                  'Séries ilimitadas',
                  'Sem anúncios',
                  'Qualidade Full HD / 4K',
                  'Até 4 perfis',
                  'Continuar assistindo',
                  'Favoritos sincronizados',
                ].map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          benefit,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // CTA Button
                PrimaryButton(
                  label: 'COMEÇAR AGORA',
                  onPressed: () {
                    // Navigate to home
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tela de Assinaturas (Planos)
class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: '1',
      name: 'Básico',
      price: 10.0,
      screens: 2,
      maxQuality: 'Full HD (1080p)',
      features: [
        '2 telas simultâneas',
        'Qualidade Full HD (1080p)',
        'Todo o catálogo',
        'Sem anúncios',
        'Continuar assistindo',
        'Favoritos sincronizados',
      ],
      emoji: '🟣',
    ),
    SubscriptionPlan(
      id: '2',
      name: 'Standard',
      price: 20.0,
      screens: 4,
      maxQuality: 'Full HD (1080p)',
      features: [
        '4 telas simultâneas',
        'Qualidade Full HD (1080p)',
        'Todo o catálogo',
        'Sem anúncios',
        'Downloads para offline',
        'Perfis personalizados',
      ],
      emoji: '🔵',
    ),
    SubscriptionPlan(
      id: '3',
      name: 'Premium',
      price: 30.0,
      screens: 6,
      maxQuality: '4K Ultra HD + HDR',
      features: [
        '6 telas simultâneas',
        'Qualidade 4K Ultra HD + HDR',
        'Todo o catálogo',
        'Sem anúncios',
        'Downloads ilimitados',
        'Perfis personalizados',
        'Prioridade em novos recursos',
      ],
      emoji: '👑',
      isPopular: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Escolha seu Plano'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Selecione o plano perfeito para você',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              // Subscription Cards
              ...plans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _SubscriptionCard(plan: plan),
              )),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final int screens;
  final String maxQuality;
  final List<String> features;
  final String emoji;
  final bool isPopular;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.screens,
    required this.maxQuality,
    required this.features,
    required this.emoji,
    this.isPopular = false,
  });
}

class _SubscriptionCard extends StatelessWidget {
  final SubscriptionPlan plan;

  const _SubscriptionCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: plan.isPopular
                ? AppColors.primaryGradient
                : LinearGradient(
                    colors: [
                      AppColors.cardBackground,
                      AppColors.cardBackgroundLight,
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: plan.isPopular
                ? [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R\$ ${plan.price.toStringAsFixed(2)}/mês',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Screens: ${plan.screens}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Features
              ...plan.features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: plan.isPopular
                            ? AppColors.textPrimary
                            : AppColors.primaryPurple,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: plan.isPopular
                        ? Colors.white
                        : AppColors.primaryPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'ASSINAR',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: plan.isPopular
                          ? AppColors.background
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (plan.isPopular)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mais Popular',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Tela Trial Expirado
class TrialExpiredScreen extends StatelessWidget {
  const TrialExpiredScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                
                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'Seu período gratuito terminou',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  'Escolha um plano e continue aproveitando todo o catálogo do Nexustwos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 40),
                
                // CTA
                PrimaryButton(
                  label: 'VER PLANOS',
                  onPressed: () {
                    // Navigate to subscriptions
                  },
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
