import 'package:flutter_bloc/flutter_bloc.dart';
import 'ornek_yazililar_event.dart';
import 'ornek_yazililar_state.dart';

class OrnekYazililarBloc extends Bloc<OrnekYazililarEvent, OrnekYazililarState> {
  OrnekYazililarBloc() : super(const OrnekYazililarState()) {
    on<LoadDocumentsEvent>(_onLoadDocuments);
  }

  Future<void> _onLoadDocuments(
    LoadDocumentsEvent event,
    Emitter<OrnekYazililarState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));
    
    try {
      // TODO: Load documents from service
      await Future.delayed(const Duration(seconds: 1));
      
      emit(state.copyWith(
        isLoading: false,
        documents: const ['Document 1', 'Document 2', 'Document 3'],
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }
}

