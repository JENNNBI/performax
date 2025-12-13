part of 'bottom_nav_visibility_bloc.dart';

/// Events for controlling bottom navigation bar visibility
abstract class BottomNavVisibilityEvent extends Equatable {
  const BottomNavVisibilityEvent();

  @override
  List<Object?> get props => [];
}

/// Show the bottom navigation bar
class ShowBottomNav extends BottomNavVisibilityEvent {
  const ShowBottomNav();
}

/// Hide the bottom navigation bar
class HideBottomNav extends BottomNavVisibilityEvent {
  const HideBottomNav();
}

