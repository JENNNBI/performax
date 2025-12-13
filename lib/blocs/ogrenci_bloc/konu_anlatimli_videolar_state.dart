import 'package:equatable/equatable.dart';

class KonuAnlatimliVideolarState extends Equatable {
  final bool isLoading;
  final List<String> videos;
  final String? error;

  const KonuAnlatimliVideolarState({
    this.isLoading = false,
    this.videos = const [],
    this.error,
  });

  KonuAnlatimliVideolarState copyWith({
    bool? isLoading,
    List<String>? videos,
    String? error,
  }) {
    return KonuAnlatimliVideolarState(
      isLoading: isLoading ?? this.isLoading,
      videos: videos ?? this.videos,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isLoading, videos, error];
}

