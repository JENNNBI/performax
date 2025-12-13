import 'package:flutter/material.dart';
import '../services/favorites_service.dart';
import '../models/favorite_question.dart';
import '../blocs/bloc_exports.dart';

/// Screen to display all favorite questions
class FavoriteQuestionsScreen extends StatefulWidget {
  static const String id = 'favorite_questions_screen';
  
  const FavoriteQuestionsScreen({super.key});

  @override
  State<FavoriteQuestionsScreen> createState() => _FavoriteQuestionsScreenState();
}

class _FavoriteQuestionsScreenState extends State<FavoriteQuestionsScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  bool _hasFixedPaths = false;

  @override
  void initState() {
    super.initState();
    // Fix all incorrect image paths when screen loads (one-time operation)
    _fixAllImagePaths();
  }

  /// Fix all incorrect image paths in Firestore
  Future<void> _fixAllImagePaths() async {
    if (_hasFixedPaths) return; // Only run once
    
    try {
      final fixedCount = await _favoritesService.fixAllImagePaths();
      if (fixedCount > 0 && mounted) {
        setState(() {
          _hasFixedPaths = true;
        });
        debugPrint('✅ Fixed $fixedCount image paths. Screen will refresh.');
      }
    } catch (e) {
      debugPrint('⚠️ Error fixing image paths: $e');
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
              isEnglish ? 'Favorite Questions' : 'Favori Sorular',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
          ),
          body: StreamBuilder<List<FavoriteQuestion>>(
            stream: _favoritesService.getFavoriteQuestions(),
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
                        isEnglish ? 'Loading favorites...' : 'Favoriler yükleniyor...',
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
                          isEnglish ? 'Error loading favorites' : 'Favoriler yüklenirken hata',
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
              final favorites = snapshot.data ?? [];
              debugPrint('📊 Displaying ${favorites.length} favorite questions');
              
              // Handle empty state
              if (favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isEnglish ? 'No favorite questions yet' : 'Henüz favori soru yok',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEnglish 
                          ? 'Tap the heart icon while solving questions to add them here'
                          : 'Soru çözerken kalp ikonuna dokunarak buraya ekleyin',
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
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final favorite = favorites[index];
                  
                  return _buildFavoriteQuestionCard(
                    favorite: favorite,
                    theme: theme,
                    isEnglish: isEnglish,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFavoriteQuestionCard({
    required FavoriteQuestion favorite,
    required ThemeData theme,
    required bool isEnglish,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with test name and question number
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.1),
                  theme.primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${isEnglish ? "Q" : "Soru"} ${favorite.questionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    favorite.testName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeFromFavorites(favorite),
                  tooltip: isEnglish ? 'Remove' : 'Kaldır',
                ),
              ],
            ),
          ),
          
          // Question Image
          if (favorite.imagePath.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  favorite.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('❌ Failed to load image: ${favorite.imagePath}');
                    debugPrint('   Error: $error');
                    
                    // Try to fix common path issues as fallback
                    String? fallbackPath;
                    if (favorite.imagePath.contains('test') && !favorite.imagePath.contains('/soru')) {
                      // Fix missing slash
                      fallbackPath = favorite.imagePath.replaceAllMapped(
                        RegExp(r'(test\d+)(soru\d+)', caseSensitive: false),
                        (match) => '${match.group(1)}/${match.group(2)}',
                      );
                      debugPrint('   Trying fallback path: $fallbackPath');
                    }
                    
                    return Container(
                      height: 200,
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              isEnglish ? 'Image not found' : 'Görsel bulunamadı',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            if (fallbackPath != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                isEnglish ? 'Path: ${favorite.imagePath}' : 'Yol: ${favorite.imagePath}',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Answer info if available
          if (favorite.userAnswer != null || favorite.correctAnswer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (favorite.userAnswer != null) ...[
                    _buildAnswerChip(
                      label: '${isEnglish ? "Your Answer" : "Cevabınız"}: ${favorite.userAnswer}',
                      color: favorite.userAnswer == favorite.correctAnswer
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (favorite.correctAnswer != null)
                    _buildAnswerChip(
                      label: '${isEnglish ? "Correct" : "Doğru"}: ${favorite.correctAnswer}',
                      color: Colors.green,
                    ),
                ],
              ),
            ),
          
          // Date added
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              '${isEnglish ? "Added" : "Eklenme"}: ${_formatDate(favorite.createdAt, isEnglish)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatDate(DateTime date, bool isEnglish) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return isEnglish 
            ? '${difference.inMinutes} minutes ago'
            : '${difference.inMinutes} dakika önce';
      }
      return isEnglish 
          ? '${difference.inHours} hours ago'
          : '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return isEnglish ? 'Yesterday' : 'Dün';
    } else if (difference.inDays < 7) {
      return isEnglish 
          ? '${difference.inDays} days ago'
          : '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  Future<void> _removeFromFavorites(FavoriteQuestion favorite) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Favorilerden Çıkar'),
        content: Text('Soru ${favorite.questionNumber} favorilerinizden kaldırılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Kaldır', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _favoritesService.removeFavoriteQuestion(
        testName: favorite.testName,
        questionNumber: favorite.questionNumber,
      );
    }
  }
}

