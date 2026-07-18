import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_widgets.dart';

// ============================================
// HOME SCREEN - Premium Edition
// ============================================

class HomeScreenPremium extends StatefulWidget {
  const HomeScreenPremium({super.key});

  @override
  State<HomeScreenPremium> createState() => _HomeScreenPremiumState();
}

class _HomeScreenPremiumState extends State<HomeScreenPremium>
    with SingleTickerProviderStateMixin {
  late PageController _bannerController;
  int _currentBannerIndex = 0;
  late AnimationController _animationController;

  final List<BannerItem> banners = [
    BannerItem(
      id: '1',
      title: 'The Amazing Journey',
      image: 'https://via.placeholder.com/1200x600?text=Movie+1',
      rating: 8.9,
      isNew: true,
    ),
    BannerItem(
      id: '2',
      title: 'Infinite Possibilities',
      image: 'https://via.placeholder.com/1200x600?text=Movie+2',
      rating: 8.7,
      isNew: false,
    ),
    BannerItem(
      id: '3',
      title: 'Beyond Dimensions',
      image: 'https://via.placeholder.com/1200x600?text=Movie+3',
      rating: 9.2,
      isNew: true,
    ),
  ];

  final List<MediaItem> continueWatching = [
    MediaItem(
      id: '1',
      title: 'The Crown - S06E02',
      image: 'https://via.placeholder.com/150x225?text=Series',
      progress: 0.65,
    ),
    MediaItem(
      id: '2',
      title: 'The Last of Us',
      image: 'https://via.placeholder.com/150x225?text=Movie',
      progress: 0.45,
    ),
  ];

  final List<MediaItem> releases = [
    MediaItem(
      id: '1',
      title: 'Lançamento 1',
      image: 'https://via.placeholder.com/150x225?text=New+1',
    ),
    MediaItem(
      id: '2',
      title: 'Lançamento 2',
      image: 'https://via.placeholder.com/150x225?text=New+2',
    ),
    MediaItem(
      id: '3',
      title: 'Lançamento 3',
      image: 'https://via.placeholder.com/150x225?text=New+3',
    ),
    MediaItem(
      id: '4',
      title: 'Lançamento 4',
      image: 'https://via.placeholder.com/150x225?text=New+4',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar com gradiente
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            expandedHeight: 80,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.background.withOpacity(0.5),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
              title: Text(
                'NEXUSTWOS',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.5,
                ),
              ),
              centerTitle: false,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, '/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () => Navigator.pushNamed(context, '/profile'),
              ),
            ],
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Carousel
                  _buildBannerCarousel(),

                  const SizedBox(height: 40),

                  // Continue Watching
                  if (continueWatching.isNotEmpty) ...[
                    _buildSectionTitle('Continue assistindo'),
                    _buildHorizontalCarousel(continueWatching, hasProgress: true),
                    const SizedBox(height: 40),
                  ],

                  // Lançamentos
                  _buildSectionTitle('Lançamentos'),
                  _buildHorizontalCarousel(releases),
                  const SizedBox(height: 40),

                  // Categorias rápidas
                  _buildCategoriesGrid(),
                  const SizedBox(height: 40),

                  // Filmes em destaque
                  _buildSectionTitle('Filmes em Destaque'),
                  _buildHorizontalCarousel(releases),
                  const SizedBox(height: 40),

                  // Séries populares
                  _buildSectionTitle('Séries Populares'),
                  _buildHorizontalCarousel(releases),
                  const SizedBox(height: 40),

                  // Top 10
                  _buildSectionTitle('Top 10 Hoje'),
                  _buildTop10List(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() => _currentBannerIndex = index);
            },
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerItem(banner);
            },
          ),
        ),

        const SizedBox(height: 16),

        // Indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentBannerIndex == index ? 24 : 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
                    ? AppColors.primaryPurple
                    : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerItem(BannerItem banner) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/movie-details', arguments: banner.id);
      },
      child: Stack(
        children: [
          // Imagem com overlay
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                banner.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.cardBackground,
                  );
                },
              ),
            ),
          ),

          // Overlay gradient
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Conteúdo
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (banner.isNew)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🆕 NOVO',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  banner.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${banner.rating}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label: '▶ ASSISTIR',
                        height: 40,
                        onPressed: () {
                          Navigator.pushNamed(context, '/player',
                              arguments: banner.id);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildHorizontalCarousel(
    List<MediaItem> items, {
    bool hasProgress = false,
  }) {
    return SizedBox(
      height: hasProgress ? 240 : 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/movie-details',
                  arguments: item.id);
            },
            child: Container(
              margin: EdgeInsets.only(right: index == items.length - 1 ? 0 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.network(
                          item.image,
                          width: 150,
                          height: 225,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 150,
                              height: 225,
                              color: AppColors.cardBackground,
                            );
                          },
                        ),
                        if (hasProgress && item.progress != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.primaryPurple.withOpacity(0.8),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: item.progress!,
                                child: Container(
                                  color: AppColors.primaryPurple,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Título
                  SizedBox(
                    width: 150,
                    child: Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    final categories = [
      ('🎬 Filmes', '/categories?type=movies'),
      ('📺 Séries', '/categories?type=series'),
      ('🎨 Animes', '/categories?type=anime'),
      ('👶 Infantil', '/categories?type=kids'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final (label, route) = categories[index];
          return GestureDetector(
            onTap: () => Navigator.pushNamed(context, route),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.3),
                    AppColors.primaryBlue.withOpacity(0.3),
                  ],
                ),
                border: Border.all(
                  color: AppColors.cardBackground,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTop10List() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: List.generate(
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Ranking
                Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Poster e info
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://via.placeholder.com/50x75?text=${index + 1}',
                    width: 50,
                    height: 75,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 50,
                        height: 75,
                        color: AppColors.cardBackground,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 12),

                // Título e detalhes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filme Top ${index + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${8.5 + (index * 0.1)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Play button
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  color: AppColors.primaryPurple,
                  onPressed: () =>
                      Navigator.pushNamed(context, '/player'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BannerItem {
  final String id;
  final String title;
  final String image;
  final double rating;
  final bool isNew;

  BannerItem({
    required this.id,
    required this.title,
    required this.image,
    required this.rating,
    this.isNew = false,
  });
}

class MediaItem {
  final String id;
  final String title;
  final String image;
  final double? progress;

  MediaItem({
    required this.id,
    required this.title,
    required this.image,
    this.progress,
  });
}

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
