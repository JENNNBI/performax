import 'package:equatable/equatable.dart';

class SoruCozumVideolariState extends Equatable {
  final bool isLoading;
  final List<String> videos;
  final String? error;

  const SoruCozumVideolariState({
    this.isLoading = false,
    this.videos = const [],
    this.error,
  });

  SoruCozumVideolariState copyWith({
    bool? isLoading,
    List<String>? videos,
    String? error,
  }) {
    return SoruCozumVideolariState(
      isLoading: isLoading ?? this.isLoading,
      videos: videos ?? this.videos,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, videos, error];
}

