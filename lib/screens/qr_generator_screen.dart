import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/qr_generator_service.dart';
import '../blocs/bloc_exports.dart';

class QRGeneratorScreen extends StatefulWidget {
  static const String id = 'qr_generator_screen';
  
  const QRGeneratorScreen({super.key});

  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoIdController = TextEditingController();
  final _urlController = TextEditingController();
  final _textController = TextEditingController();
  final _gradeController = TextEditingController();

  String _selectedType = 'video';
  String _selectedSubject = 'Matematik';
  String _selectedSection = 'topic_videos';
  String _generatedQRData = '';
  bool _isGenerated = false;

  final List<String> _subjects = [
    'Matematik', 'Fizik', 'Kimya', 'Biyoloji',
    'Türkçe', 'Tarih', 'Coğrafya', 'Felsefe'
  ];

  final List<String> _sections = [
    'topic_videos', 'problem_solving', 'sample_exams'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoIdController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _gradeController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isGenerated = false;
    });

    String qrData = '';

    switch (_selectedType) {
      case 'video':
        if (_videoIdController.text.trim().isEmpty) {
          _showError('Please enter a video ID');
          return;
        }
        qrData = QRGeneratorService.instance.generateVideoQR(
          videoId: _videoIdController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
      case 'subject':
        qrData = QRGeneratorService.instance.generateSubjectQR(
          subjectName: _selectedSubject,
          sectionType: _selectedSection,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
      case 'exam':
        if (_gradeController.text.trim().isEmpty) {
          _showError('Please enter a grade');
          return;
        }
        qrData = QRGeneratorService.instance.generateExamQR(
          subjectName: _selectedSubject,
          grade: _gradeController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
      case 'practice':
        if (_gradeController.text.trim().isEmpty) {
          _showError('Please enter a grade');
          return;
        }
        qrData = QRGeneratorService.instance.generatePracticeQR(
          subjectName: _selectedSubject,
          grade: _gradeController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
      case 'url':
        if (_urlController.text.trim().isEmpty) {
          _showError('Please enter a URL');
          return;
        }
        qrData = QRGeneratorService.instance.generateURLQR(
          url: _urlController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
      case 'text':
        if (_textController.text.trim().isEmpty) {
          _showError('Please enter text content');
          return;
        }
        qrData = QRGeneratorService.instance.generateTextQR(
          text: _textController.text.trim(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        );
        break;
    }

    setState(() {
      _generatedQRData = qrData;
      _isGenerated = true;
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedQRData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR data copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(languageBloc.translate('qr_generator')),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Content Type Selection
                  Text(
                    languageBloc.translate('content_type'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'video',
                        child: Text(languageBloc.translate('video')),
                      ),
                      DropdownMenuItem(
                        value: 'subject',
                        child: Text(languageBloc.translate('subject')),
                      ),
                      DropdownMenuItem(
                        value: 'exam',
                        child: Text(languageBloc.translate('exam')),
                      ),
                      DropdownMenuItem(
                        value: 'practice',
                        child: Text(languageBloc.translate('practice')),
                      ),
                      DropdownMenuItem(
                        value: 'url',
                        child: Text(languageBloc.translate('url')),
                      ),
                      DropdownMenuItem(
                        value: 'text',
                        child: Text(languageBloc.translate('text')),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _isGenerated = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: languageBloc.translate('title'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return languageBloc.translate('title_required');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: languageBloc.translate('description'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  // Type-specific fields
                  if (_selectedType == 'video') ...[
                    TextFormField(
                      controller: _videoIdController,
                      decoration: InputDecoration(
                        labelText: 'YouTube Video ID',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText: 'Enter 11-character YouTube video ID',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedType == 'subject') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: InputDecoration(
                        labelText: languageBloc.translate('subject'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSection,
                      decoration: InputDecoration(
                        labelText: languageBloc.translate('section'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _sections.map((section) {
                        return DropdownMenuItem(
                          value: section,
                          child: Text(section),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSection = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedType == 'exam' || _selectedType == 'practice') ...[
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      decoration: InputDecoration(
                        labelText: languageBloc.translate('subject'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gradeController,
                      decoration: InputDecoration(
                        labelText: languageBloc.translate('grade'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText: 'Enter grade level (e.g., 9, 10, 11, 12)',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return languageBloc.translate('grade_required');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedType == 'url') ...[
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        helperText: 'Enter full URL (e.g., https://example.com)',
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (_selectedType == 'text') ...[
                    TextFormField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: languageBloc.translate('text_content'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Generate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _generateQR,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        languageBloc.translate('generate_qr'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generated QR Data
                  if (_isGenerated) ...[
                    Text(
                      languageBloc.translate('generated_qr_data'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[50],
                      ),
                      child: SelectableText(
                        _generatedQRData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(Icons.copy),
                            label: Text(languageBloc.translate('copy')),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isGenerated = false;
                                _generatedQRData = '';
                              });
                            },
                            icon: const Icon(Icons.refresh),
                            label: Text(languageBloc.translate('generate_new')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
