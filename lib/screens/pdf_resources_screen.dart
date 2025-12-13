import 'package:flutter/material.dart';
import '../models/pdf_resource.dart';
import '../widgets/flipbook_viewer.dart';
import '../blocs/bloc_exports.dart';

class PDFResourcesScreen extends StatefulWidget {
  static const String id = 'pdf_resources_screen';
  
  const PDFResourcesScreen({super.key});

  @override
  State<PDFResourcesScreen> createState() => _PDFResourcesScreenState();
}

class _PDFResourcesScreenState extends State<PDFResourcesScreen> {
  String _selectedSubject = 'All';
  String _selectedGrade = 'All';
  
  final List<String> _subjects = [
    'All', 'Biology', 'Mathematics', 'Physics', 'Chemistry',
    'Turkish', 'History', 'Geography', 'Philosophy'
  ];
  
  final List<String> _grades = [
    'All', '9', '10', '11', '12'
  ];

  // Sample PDF resources - in a real app, this would come from a service
  final List<PDFResource> _resources = [
    PDFResource.biology9thGrade(),
    PDFResource.textbook(
      id: 'math_9th_grade',
      title: 'Mathematics 9th Grade Textbook',
      subject: 'Mathematics',
      grade: '9',
      url: 'https://example.com/math-9th.pdf',
      description: 'Comprehensive mathematics textbook for 9th grade students',
      author: 'Ministry of Education',
      totalPages: 250,
    ),
    PDFResource.textbook(
      id: 'physics_10th_grade',
      title: 'Physics 10th Grade Textbook',
      subject: 'Physics',
      grade: '10',
      url: 'https://example.com/physics-10th.pdf',
      description: 'Interactive physics textbook with experiments and simulations',
      author: 'Educational Publishing',
      totalPages: 300,
    ),
    PDFResource.textbook(
      id: 'chemistry_11th_grade',
      title: 'Chemistry 11th Grade Textbook',
      subject: 'Chemistry',
      grade: '11',
      url: 'https://example.com/chemistry-11th.pdf',
      description: 'Advanced chemistry concepts with interactive demonstrations',
      author: 'Science Publishers',
      totalPages: 280,
    ),
  ];

  List<PDFResource> get _filteredResources {
    return _resources.where((resource) {
      final subjectMatch = _selectedSubject == 'All' || resource.subject == _selectedSubject;
      final gradeMatch = _selectedGrade == 'All' || resource.grade == _selectedGrade;
      return subjectMatch && gradeMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Column(
            children: [
              // Filter section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    // Subject filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: languageBloc.translate('subject'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Grade filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGrade,
                        decoration: InputDecoration(
                          labelText: languageBloc.translate('grade'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: _grades.map((grade) {
                          return DropdownMenuItem(
                            value: grade,
                            child: Text(grade),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              // Resources list
              Expanded(
                child: _filteredResources.isEmpty
                    ? _buildEmptyState(languageBloc)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Add bottom padding for BottomAppBar
                        itemCount: _filteredResources.length,
                        itemBuilder: (context, index) {
                          final resource = _filteredResources[index];
                          return _buildResourceCard(resource, languageBloc);
                        },
                      ),
              ),
            ],
          );
      },
    );
  }

  Widget _buildEmptyState(LanguageBloc languageBloc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            languageBloc.currentLanguage == 'tr'
                ? 'Seçilen kriterlere uygun kaynak bulunamadı'
                : 'No resources found matching the selected criteria',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            languageBloc.currentLanguage == 'tr'
                ? 'Farklı bir konu veya sınıf seçmeyi deneyin'
                : 'Try selecting a different subject or grade',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResourceCard(PDFResource resource, LanguageBloc languageBloc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openFlipbook(resource),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 80,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: resource.thumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(resource.thumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: resource.thumbnailUrl == null
                    ? Icon(
                        Icons.book,
                        size: 40,
                        color: Colors.grey[400],
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and grade badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            resource.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Grade ${resource.grade}',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Subject
                    Text(
                      resource.subject,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    Text(
                      resource.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Metadata
                    Row(
                      children: [
                        if (resource.totalPages != null) ...[
                          Icon(
                            Icons.pages,
                            size: 16,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${resource.totalPages} pages',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (resource.isInteractive) ...[
                          Icon(
                            Icons.touch_app,
                            size: 16,
                            color: Colors.green[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            languageBloc.currentLanguage == 'tr'
                                ? 'İnteraktif'
                                : 'Interactive',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow icon
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFlipbook(PDFResource resource) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FlipbookViewer(
          resource: resource,
        ),
      ),
    );
  }
}
