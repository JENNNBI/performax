import 'package:flutter_bloc/flutter_bloc.dart';
import 'konu_anlatimli_videolar_event.dart';
import 'konu_anlatimli_videolar_state.dart';

class KonuAnlatimliVideolarBloc extends Bloc<KonuAnlatimliVideolarEvent, KonuAnlatimliVideolarState> {
  KonuAnlatimliVideolarBloc() : super(const KonuAnlatimliVideolarState()) {
    on<LoadVideosEvent>(_onLoadVideos);
  }

  Future<void> _onLoadVideos(
    LoadVideosEvent event,
    Emitter<KonuAnlatimliVideolarState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // TODO: Load videos from service
      await Future.delayed(const Duration(seconds: 1));
      
      emit(state.copyWith(
        isLoading: false,
        videos: const ['Video 1', 'Video 2', 'Video 3'],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

