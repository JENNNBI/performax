// lib/screens/soru_cozum_videolari_screen.dart
import 'package:flutter/material.dart';
import 'package:performax/blocs/ogrenci_bloc/soru_cozum_videolari_bloc.dart';
import 'package:performax/screens/my_drawer.dart';
import '../blocs/bloc_exports.dart'; // Add this import

class SoruCozumVideolariScreen extends StatelessWidget {
  static const String id = 'soru_cozum_videolari_screen';

  const SoruCozumVideolariScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return Text(context.read<LanguageBloc>().translate('problem_solving_videos'));
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
      body: BlocBuilder<SoruCozumVideolariBloc, SoruCozumVideolariState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: state.videos.length,
            itemBuilder: (context, index) {
              return ListTile(title: Text(state.videos[index]));
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<SoruCozumVideolariBloc>().add(LoadSolutionVideosEvent()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}