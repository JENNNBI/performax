import 'package:equatable/equatable.dart';

class OrnekYazililarState extends Equatable {
  final bool isLoading;
  final List<String> documents;
  final String? error;

  const OrnekYazililarState({
    this.isLoading = false,
    this.documents = const [],
    this.error,
  });

  OrnekYazililarState copyWith({
    bool? isLoading,
    List<String>? documents,
    String? error,
  }) {
    return OrnekYazililarState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, documents, error];
}

