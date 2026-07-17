import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_widgets.dart';
import '../../models/models.dart';

/// Home Screen Premium com Design Nexustwos
class HomeScreenPremium extends StatefulWidget {
  const HomeScreenPremium({Key? key}) : super(key: key);

  @override
  State<HomeScreenPremium> createState() => _HomeScreenPremiumState();
}

class _HomeScreenPremiumState extends State<HomeScreenPremium> {
  int _bannerIndex = 0;
  bool _isLoading = true;

  final List<Map<String, String>> banners = [
    {
      'title': 'Novo Lançamento',
      'subtitle': 'Disponível em 4K',
      'image': 'https://via.placeholder.com/400x225?text=Banner1',
    },
    {
      'title': 'Série do Momento',
      'subtitle': 'Temporada 2 ao vivo',
      'image': 'https://via.placeholder.com/400x225?text=Banner2',
    },
    {
      'title': 'Clássicos Remaster',
      'subtitle': 'Restaurado em 4K HDR',
      'image': 'https://via.placeholder.com/400x225?text=Banner3',
    },
  ];

  final List<MediaCategory> categories = [
    MediaCategory(
      title: 'Continuar Assistindo',
      icon: Icons.play_circle_outline,
    ),
    MediaCategory(
      title: 'Lançamentos',
      icon: Icons.new_releases_outlined,
    ),
    MediaCategory(
      title: 'Em Alta',
      icon: Icons.trending_up,
    ),
    MediaCategory(
      title: 'Recomendados',
      icon: Icons.recommend_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: Text(
          'Nexustwos',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primaryPurple,
              backgroundColor: AppColors.cardBackground,
              child: _buildContent(),
            ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SkeletonLoader(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 280,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: SkeletonLoader(
                    width: 150,
                    height: 280,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Banner Carousel
          _buildFeatureBanner(),
          const SizedBox(height: 32),

          // Quick Category Chips
          _buildCategoryChips(),
          const SizedBox(height: 24),

          // Content Sections
          ...[
            MediaCategory(
              title: 'Continuar Assistindo',
              icon: Icons.play_circle_outline,
            ),
            MediaCategory(
              title: 'Lançamentos',
              icon: Icons.new_releases_outlined,
            ),
            MediaCategory(
              title: 'Em Alta',
              icon: Icons.trending_up,
            ),
            MediaCategory(
              title: 'Recomendados para Você',
              icon: Icons.recommend_outlined,
            ),
          ].map((category) => _buildMediaSection(category)).toList(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFeatureBanner() {
    return Column(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 220,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            enlargeCenterPage: false,
            viewportFraction: 0.95,
            onPageChanged: (index, reason) {
              setState(() => _bannerIndex = index);
            },
          ),
          items: banners
              .map(
                (banner) => GestureDetector(
                  onTap: () {
                    // Navigate to details
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            banner['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.cardBackground,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              );
                            },
                          ),
                        ),
                        // Gradient overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                banner['title']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['subtitle']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Play button
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        // Pagination dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => Container(
              width: _bannerIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: _bannerIndex == index
                    ? AppColors.primaryGradient
                    : null,
                color: _bannerIndex == index
                    ? null
                    : AppColors.textTertiary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final chips = [
      'Filmes',
      'Séries',
      'Animes',
      'Infantil',
      'Documentários',
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: CategoryTag(
            label: chips[index],
            isSelected: index == 0,
            onTap: () {},
          ),
        ),
      ),
    );
  }

  Widget _buildMediaSection(MediaCategory category) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      category.icon,
                      color: AppColors.primaryPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'Ver tudo',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: MediaCard(
                  imageUrl:
                      'https://via.placeholder.com/150x225?text=Media${index + 1}',
                  title: 'Título do Filme/Série ${index + 1}',
                  subtitle: '${2024 - index} • 1h 48min',
                  rating: 8.5 - (index * 0.2),
                  onTap: () {
                    // Navigate to details
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MediaCategory {
  final String title;
  final IconData icon;

  MediaCategory({
    required this.title,
    required this.icon,
  });
}
