import 'package:flutter_bloc/flutter_bloc.dart';
import 'soru_cozum_videolari_event.dart';
import 'soru_cozum_videolari_state.dart';

class SoruCozumVideolariBloc extends Bloc<SoruCozumVideolariEvent, SoruCozumVideolariState> {
  SoruCozumVideolariBloc() : super(const SoruCozumVideolariState()) {
    on<LoadSolutionVideosEvent>(_onLoadSolutionVideos);
  }

  Future<void> _onLoadSolutionVideos(
    LoadSolutionVideosEvent event,
    Emitter<SoruCozumVideolariState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // TODO: Load solution videos from service
      await Future.delayed(const Duration(seconds: 1));
      
      emit(state.copyWith(
        isLoading: false,
        videos: const ['Solution Video 1', 'Solution Video 2', 'Solution Video 3'],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

