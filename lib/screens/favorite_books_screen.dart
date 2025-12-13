import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/favorite_book.dart';
import '../blocs/bloc_exports.dart';
import 'test_selection_screen.dart';

/// Screen to display all favorite books with cover images
class FavoriteBooksScreen extends StatefulWidget {
  static const String id = 'favorite_books_screen';
  
  const FavoriteBooksScreen({super.key});

  @override
  State<FavoriteBooksScreen> createState() => _FavoriteBooksScreenState();
}

class _FavoriteBooksScreenState extends State<FavoriteBooksScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  // Helper function to get gradient colors based on subject
  List<Color> _getGradientColors(String subject) {
    final subjectLower = subject.toLowerCase();
    switch (subjectLower) {
      case 'matematik':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      case 'fizik':
        return [const Color(0xFFf093fb), const Color(0xFFf5576c)];
      case 'kimya':
        return [const Color(0xFF4facfe), const Color(0xFF00f2fe)];
      case 'biyoloji':
        return [const Color(0xFF43e97b), const Color(0xFF38f9d7)];
      case 'türkçe':
        return [const Color(0xFFfa709a), const Color(0xFFfee140)];
      case 'tarih':
        return [const Color(0xFF30cfd0), const Color(0xFF330867)];
      case 'coğrafya':
        return [const Color(0xFFa8edea), const Color(0xFFfed6e3)];
      default:
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
    }
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
            title: Text(
              isEnglish ? 'Favorite Books' : 'Favori Kitaplar',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<List<FavoriteBook>>(
            stream: _favoritesService.getFavoriteBooks(),
            builder: (context, snapshot) {
              // Handle loading state
              if (snapshot.connectionState == ConnectionState.waiting ||
                  snapshot.connectionState == ConnectionState.none) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'Loading favorite books...' : 'Favori kitaplar yükleniyor...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Handle errors
              if (snapshot.hasError) {
                debugPrint('❌ StreamBuilder error: ${snapshot.error}');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          isEnglish ? 'Error loading favorite books' : 'Favori kitaplar yüklenirken hata',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Refresh by rebuilding the stream
                            setState(() {});
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(isEnglish ? 'Retry' : 'Yeniden Dene'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Get favorites data
              final favoriteBooks = snapshot.data ?? [];
              debugPrint('📊 Displaying ${favoriteBooks.length} favorite books');
              
              // Handle empty state
              if (favoriteBooks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'No favorite books yet' : 'Henüz favori kitap yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEnglish 
                          ? 'Tap the heart icon in test selection to add books here'
                          : 'Test seçim ekranında kalp ikonuna dokunarak kitapları buraya ekleyin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              // Grid view for favorite books
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: favoriteBooks.length,
                itemBuilder: (context, index) {
                  final book = favoriteBooks[index];
                  final gradientColors = _getGradientColors(book.subject);
                  
                  return _buildFavoriteBookCard(
                    book: book,
                    theme: theme,
                    isEnglish: isEnglish,
                    gradientStart: gradientColors[0],
                    gradientEnd: gradientColors[1],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteBookCard({
    required FavoriteBook book,
    required ThemeData theme,
    required bool isEnglish,
    required Color gradientStart,
    required Color gradientEnd,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to Test Selection Screen
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TestSelectionScreen(
              testSeriesTitle: book.testSeriesTitle,
              subject: book.subject,
              grade: book.grade,
              testSeriesKey: book.testSeriesKey,
              coverImagePath: book.coverImagePath,
              totalTests: 5, // Default value, can be enhanced later
              gradientStart: gradientStart,
              gradientEnd: gradientEnd,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book Cover Image
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      book.coverImagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint('❌ Failed to load book cover: ${book.coverImagePath}');
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gradientStart, gradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      },
                    ),
                    // Favorite indicator overlay
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Book Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Book Title
                    Text(
                      book.testSeriesTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subject and Grade
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradientStart.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.subject,
                            style: TextStyle(
                              fontSize: 10,
                              color: gradientStart,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gradientEnd.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            book.grade.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: gradientEnd,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Tap to open indicator
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEnglish ? 'Tap to open' : 'Açmak için dokun',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

