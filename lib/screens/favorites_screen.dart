import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import 'favorite_questions_screen.dart';
import 'favorite_books_screen.dart';
import 'favorite_playlists_screen.dart';

class FavoritesScreen extends StatefulWidget {
  static const String id = 'favorites_screen';

  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  late AnimationController _headerController;
  late AnimationController _cardsController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    try {
      _headerController = AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      );
      
      _cardsController = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );
      
      _headerFadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOut,
      ));
      
      _headerSlideAnimation = Tween<Offset>(
        begin: const Offset(0, -0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ));
      
      // Start animations
      _headerController.forward();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          _cardsController.forward();
        }
      });
    } catch (e) {
      debugPrint('Error initializing Favorites Screen: $e');
    }
  }

  @override
  void dispose() {
    try {
      _headerController.dispose();
      _cardsController.dispose();
    } catch (e) {
      debugPrint('Error disposing Favorites Screen: $e');
    }
    super.dispose();
  }

  void _showComingSoonNotification(String itemType) {
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      content: AwesomeSnackbarContent(
        title: 'Yakında Gelecek',
        message: '$itemType özelliği yakında kullanıma sunulacak!',
        contentType: ContentType.help,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  void _navigateToFavoriteQuestions() {
    Navigator.pushNamed(context, FavoriteQuestionsScreen.id);
  }
  
  void _navigateToFavoriteBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoriteBooksScreen()),
    );
  }
  
  void _navigateToFavoritePlaylists() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritePlaylistsScreen()),
    );
  }

  Widget _buildAnimatedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color startColor,
    required Color endColor,
    required VoidCallback onTap,
    required int index,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardsController,
        curve: Interval(
          index * 0.1,
          0.5 + (index * 0.1),
          curve: Curves.easeOutCubic,
        ),
      )),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _cardsController,
            curve: Interval(
              index * 0.1,
              0.5 + (index * 0.1),
              curve: Curves.easeIn,
            ),
          ),
        ),
        child: _FavoriteCard(
          icon: icon,
          title: title,
          subtitle: subtitle,
          startColor: startColor,
          endColor: endColor,
          onTap: onTap,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final bool isEnglish = languageBloc.currentLanguage == 'en';
        
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: theme.primaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: FadeTransition(
              opacity: _headerFadeAnimation,
              child: Text(
                isEnglish ? 'Favorites' : 'FAVORİLER',
                style: TextStyle(
                  color: theme.textTheme.titleLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Header Description
                  FadeTransition(
                    opacity: _headerFadeAnimation,
                    child: SlideTransition(
                      position: _headerSlideAnimation,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0, left: 8.0, right: 8.0),
                        child: Text(
                          isEnglish 
                            ? 'Access your favorite content quickly'
                            : 'Favori içeriklerinize hızlıca ulaşın',
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Favorite Cards
                  Expanded(
                    child: ListView(
                      children: [
                        // 1. FAVORİ SORULAR (Favorite Questions) - WORKING!
                        _buildAnimatedCard(
                          icon: Icons.quiz_rounded,
                          title: isEnglish ? 'FAVORITE QUESTIONS' : 'FAVORİ SORULAR',
                          subtitle: isEnglish 
                            ? 'Your saved questions'
                            : 'Kaydettiğiniz sorular',
                          startColor: const Color(0xFF667eea),
                          endColor: const Color(0xFF764ba2),
                          onTap: _navigateToFavoriteQuestions,  // ✅ WORKING!
                          index: 0,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 2. FAVORİ KİTAPLAR (Favorite Books)
                        _buildAnimatedCard(
                          icon: Icons.book_rounded,
                          title: isEnglish ? 'FAVORITE BOOKS' : 'FAVORİ KİTAPLAR',
                          subtitle: isEnglish 
                            ? 'Your saved books'
                            : 'Kaydettiğiniz kitaplar',
                          startColor: const Color(0xFF43e97b),
                          endColor: const Color(0xFF38f9d7),
                          onTap: _navigateToFavoriteBooks,
                          index: 1,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 3. FAVORİ DENEMELER (Favorite Mock Exams)
                        _buildAnimatedCard(
                          icon: Icons.assignment_rounded,
                          title: isEnglish ? 'FAVORITE MOCK EXAMS' : 'FAVORİ DENEMELER',
                          subtitle: isEnglish 
                            ? 'Your saved mock exams'
                            : 'Kaydettiğiniz denemeler',
                          startColor: const Color(0xFFf093fb),
                          endColor: const Color(0xFFf5576c),
                          onTap: () => _showComingSoonNotification(
                            isEnglish ? 'Favorite Mock Exams' : 'FAVORİ DENEMELER'
                          ),
                          index: 2,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // 4. FAVORİ PLAYLİSTLER (Favorite Playlists)
                        _buildAnimatedCard(
                          icon: Icons.playlist_play_rounded,
                          title: isEnglish ? 'FAVORITE PLAYLISTS' : 'FAVORİ PLAYLİSTLER',
                          subtitle: isEnglish 
                            ? 'Your saved playlists'
                            : 'Kaydettiğiniz oynatma listeleri',
                          startColor: const Color(0xFFff6b9d),
                          endColor: const Color(0xFFc44569),
                          onTap: _navigateToFavoritePlaylists,
                          index: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Favorite Card Widget
class _FavoriteCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color startColor;
  final Color endColor;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.startColor,
    required this.endColor,
    required this.onTap,
  });

  @override
  State<_FavoriteCard> createState() => _FavoriteCardState();
}

class _FavoriteCardState extends State<_FavoriteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pressController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.startColor.withValues(alpha: 0.3),
                  blurRadius: _elevationAnimation.value * 3,
                  offset: Offset(0, _elevationAnimation.value * 0.5),
                  spreadRadius: _elevationAnimation.value * 0.3,
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: widget.onTap,
                onTapDown: (_) => _pressController.forward(),
                onTapUp: (_) => _pressController.reverse(),
                onTapCancel: () => _pressController.reverse(),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.startColor,
                        widget.endColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        // Icon Container
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Text Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.subtitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Arrow Icon
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

