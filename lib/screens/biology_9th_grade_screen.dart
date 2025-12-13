import 'package:flutter/material.dart';
import '../models/pdf_resource.dart';
import '../widgets/flipbook_viewer.dart';
import '../blocs/bloc_exports.dart';

class Biology9thGradeScreen extends StatelessWidget {
  static const String id = 'biology_9th_grade_screen';
  
  const Biology9thGradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final resource = PDFResource.biology9thGrade();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              languageBloc.currentLanguage == 'tr'
                  ? 'Biyoloji 9. Sınıf'
                  : 'Biology 9th Grade',
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FlipbookViewer(
                        resource: resource,
                        fullscreen: true,
                      ),
                    ),
                  );
                },
                tooltip: languageBloc.currentLanguage == 'tr'
                    ? 'Tam Ekran'
                    : 'Fullscreen',
              ),
            ],
          ),
          body: Column(
            children: [
              // Header section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green[400]!,
                      Colors.green[600]!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.science,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                languageBloc.currentLanguage == 'tr'
                                    ? 'İnteraktif Dijital Ders Kitabı'
                                    : 'Interactive Digital Textbook',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      resource.description,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.pages,
                          '${resource.totalPages} ${languageBloc.currentLanguage == 'tr' ? 'Sayfa' : 'Pages'}',
                          Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.touch_app,
                          languageBloc.currentLanguage == 'tr' ? 'İnteraktif' : 'Interactive',
                          Colors.white.withOpacity(0.2),
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.swipe,
                          languageBloc.currentLanguage == 'tr' ? 'Kaydırma' : 'Swipe',
                          Colors.white.withOpacity(0.2),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Instructions section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.grey[50],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageBloc.currentLanguage == 'tr'
                          ? 'Nasıl Kullanılır?'
                          : 'How to Use?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      context,
                      Icons.touch_app,
                      languageBloc.currentLanguage == 'tr'
                          ? 'Sayfaları çevirmek için dokunun veya kaydırın'
                          : 'Tap or swipe to turn pages',
                    ),
                    _buildInstructionItem(
                      context,
                      Icons.zoom_in,
                      languageBloc.currentLanguage == 'tr'
                          ? 'Yakınlaştırmak için çimdikleme hareketi yapın'
                          : 'Pinch to zoom in and out',
                    ),
                    _buildInstructionItem(
                      context,
                      Icons.fullscreen,
                      languageBloc.currentLanguage == 'tr'
                          ? 'Tam ekran için sağ üstteki simgeye dokunun'
                          : 'Tap the fullscreen icon for better viewing',
                    ),
                  ],
                ),
              ),
              
              // Open flipbook button
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.green[100],
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: Colors.green[300]!,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book,
                            size: 60,
                            color: Colors.green[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          languageBloc.currentLanguage == 'tr'
                              ? 'Ders Kitabını Aç'
                              : 'Open Textbook',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          languageBloc.currentLanguage == 'tr'
                              ? 'İnteraktif flipbook deneyimini başlatın'
                              : 'Start the interactive flipbook experience',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FlipbookViewer(
                                    resource: resource,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.launch, size: 24),
                            label: Text(
                              languageBloc.currentLanguage == 'tr'
                                  ? 'Flipbook\'u Aç'
                                  : 'Open Flipbook',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
