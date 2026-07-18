import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<OnboardingPage> pages = [
    OnboardingPage(
      title: 'Filmes de Classe\nMundial',
      description:
          'Acesse uma coleção exclusiva de filmes de sucesso, desde clássicos atemporais até lançamentos do momento.',
      icon: Icons.movie_outlined,
      gradient: LinearGradient(
        colors: [AppColors.primaryPurple, AppColors.primaryBlue],
      ),
    ),
    OnboardingPage(
      title: 'Séries\nImperdíveis',
      description:
          'Binge-watch suas séries favoritas. Acompanhe episódios lançados, maratonas completas e muito mais.',
      icon: Icons.tv_outlined,
      gradient: LinearGradient(
        colors: [AppColors.primaryBlue, AppColors.primaryGradientEnd],
      ),
    ),
    OnboardingPage(
      title: 'Streaming em\nAlta Qualidade',
      description:
          'Aproveite o melhor da tecnologia com reprodução em 4K, sem anúncios e em qualquer dispositivo.',
      icon: Icons.hd_outlined,
      gradient: LinearGradient(
        colors: [AppColors.accentColor, AppColors.primaryPurple],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // PageView com as telas
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: pages.length,
            itemBuilder: (context, index) {
              return _buildPage(pages[index]);
            },
          ),

          // Indicadores de página
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  height: 8,
                  width: _currentPage == index ? 32 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.primaryPurple
                        : AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),

          // Botão "Começar"
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: PrimaryButton(
              label: _currentPage == pages.length - 1
                  ? 'COMEÇAR AGORA'
                  : 'PRÓXIMO',
              onPressed: () {
                if (_currentPage == pages.length - 1) {
                  Navigator.pushReplacementNamed(context, '/login');
                } else {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              },
            ),
          ),

          // Botão "Pular"
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Pular',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.background,
            AppColors.background.withOpacity(0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone com gradiente
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: page.gradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                page.icon,
                size: 70,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 60),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Descrição
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              page.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
