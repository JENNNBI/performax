// lib/screens/konu_anlatimli_videolar_screen.dart
import 'package:flutter/material.dart';
import 'package:performax/blocs/ogrenci_bloc/konu_anlatimli_videolar_bloc.dart';
import 'package:performax/screens/my_drawer.dart';
import '../blocs/bloc_exports.dart';

class KonuAnlatimliVideolarScreen extends StatelessWidget {
  static const String id = 'konu_anlatimli_videolar_screen';

  const KonuAnlatimliVideolarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return Text(context.read<LanguageBloc>().translate('topic_explanation_videos'));
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
      body: BlocBuilder<KonuAnlatimliVideolarBloc, KonuAnlatimliVideolarState>(
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
        onPressed: () => context.read<KonuAnlatimliVideolarBloc>().add(LoadVideosEvent()),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}