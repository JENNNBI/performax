import 'package:flutter/material.dart';

class InfoScreen extends StatelessWidget {
  static const String id = 'info_screen';

  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bilgi'),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performax Hakkında',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Performax, öğrencilerin eğitim süreçlerini desteklemek için tasarlanmış bir uygulamadır.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),
              Text(
                'Özellikler',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text('• Video dersleri'),
              Text('• PDF kaynakları'),
              Text('• Soru çözümleri'),
              Text('• İstatistikler'),
              Text('• Favoriler'),
            ],
          ),
        ),
      ),
    );
  }
}

