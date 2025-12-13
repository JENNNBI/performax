// lib/screens/ornek_yazililar_screen.dart
import 'package:flutter/material.dart';
import 'package:performax/blocs/ogrenci_bloc/ornek_yazililar_bloc.dart';
import 'package:performax/screens/my_drawer.dart';
import '../blocs/bloc_exports.dart'; // Add this import

class OrnekYazililarScreen extends StatelessWidget {
  static const String id = 'ornek_yazililar_screen';

  const OrnekYazililarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return Text(context.read<LanguageBloc>().translate('sample_exams_screen'));
          },
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: MyDrawer(),
      body: BlocBuilder<OrnekYazililarBloc, OrnekYazililarState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: state.documents.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(state.documents[index]));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<OrnekYazililarBloc>().add(LoadDocumentsEvent()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}