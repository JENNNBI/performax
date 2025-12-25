import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import '../blocs/bloc_exports.dart';
import 'favorite_questions_screen.dart';
import 'favorite_books_screen.dart';
import 'favorite_playlists_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

class FavoritesScreen extends StatefulWidget {
  static const String id = 'favorites_screen';

  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  late AnimationController _cardsController;

  @override
  void initState() {
    super.initState();
    _cardsController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _cardsController.forward();
      }
    });
  }

  @override
  void dispose() {
    _cardsController.dispose();
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
    required Color accentColor,
    required VoidCallback onTap,
    required int index,
  }) {
    final textColor = NeumorphicColors.getText(context);

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
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: NeumorphicButton(
            onPressed: onTap,
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Row(
              children: [
                NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 16,
                  color: accentColor.withValues(alpha: 0.1),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: textColor.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final bool isEnglish = languageBloc.currentLanguage == 'en';
        final bgColor = NeumorphicColors.getBackground(context);
        final textColor = NeumorphicColors.getText(context);
        
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      NeumorphicButton(
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(Icons.arrow_back_rounded, color: textColor),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isEnglish ? 'Favorites' : 'Favoriler',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    children: [
                      // 1. FAVORİ SORULAR
                      _buildAnimatedCard(
                        icon: Icons.quiz_rounded,
                        title: isEnglish ? 'Favorite Questions' : 'Favori Sorular',
                        subtitle: isEnglish ? 'Your saved questions' : 'Kaydettiğiniz sorular',
                        accentColor: const Color(0xFF667eea),
                        onTap: _navigateToFavoriteQuestions,
                        index: 0,
                      ),
                      
                      // 2. FAVORİ KİTAPLAR
                      _buildAnimatedCard(
                        icon: Icons.book_rounded,
                        title: isEnglish ? 'Favorite Books' : 'Favori Kitaplar',
                        subtitle: isEnglish ? 'Your saved books' : 'Kaydettiğiniz kitaplar',
                        accentColor: const Color(0xFF43e97b),
                        onTap: _navigateToFavoriteBooks,
                        index: 1,
                      ),
                      
                      // 3. FAVORİ DENEMELER
                      _buildAnimatedCard(
                        icon: Icons.assignment_rounded,
                        title: isEnglish ? 'Favorite Mock Exams' : 'Favori Denemeler',
                        subtitle: isEnglish ? 'Your saved mock exams' : 'Kaydettiğiniz denemeler',
                        accentColor: const Color(0xFFf093fb),
                        onTap: () => _showComingSoonNotification(
                          isEnglish ? 'Favorite Mock Exams' : 'FAVORİ DENEMELER'
                        ),
                        index: 2,
                      ),
                      
                      // 4. FAVORİ PLAYLİSTLER
                      _buildAnimatedCard(
                        icon: Icons.playlist_play_rounded,
                        title: isEnglish ? 'Favorite Playlists' : 'Favori Playlistler',
                        subtitle: isEnglish ? 'Your saved playlists' : 'Kaydettiğiniz oynatma listeleri',
                        accentColor: const Color(0xFFff6b9d),
                        onTap: _navigateToFavoritePlaylists,
                        index: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
