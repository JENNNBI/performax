part of 'bottom_nav_visibility_bloc.dart';

/// State for bottom navigation bar visibility
class BottomNavVisibilityState extends Equatable {
  final bool isVisible;

  const BottomNavVisibilityState({
    required this.isVisible,
  });

  /// Initial state - bottom nav is visible by default
  const BottomNavVisibilityState.initial() : isVisible = true;

  /// Copy with method for state updates
  BottomNavVisibilityState copyWith({
    bool? isVisible,
  }) {
    return BottomNavVisibilityState(
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  List<Object?> get props => [isVisible];
}

