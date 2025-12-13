import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bottom_nav_visibility_event.dart';
part 'bottom_nav_visibility_state.dart';

/// BLoC for managing bottom navigation bar visibility
/// 
/// The Bottom Navigation Bar follows strict UI persistence rules:
/// - DEFAULT: Always visible at the base of viewport
/// - HIDDEN ON: Test Solving Screens, Video Viewing Screens, Future Content/Placeholder Screens
/// 
/// This BLoC provides centralized state management for bottom nav visibility
/// across the entire application navigation hierarchy.
class BottomNavVisibilityBloc extends Bloc<BottomNavVisibilityEvent, BottomNavVisibilityState> {
  BottomNavVisibilityBloc() : super(const BottomNavVisibilityState.initial()) {
    on<ShowBottomNav>(_onShowBottomNav);
    on<HideBottomNav>(_onHideBottomNav);
  }

  /// Handler for showing bottom navigation
  void _onShowBottomNav(ShowBottomNav event, Emitter<BottomNavVisibilityState> emit) {
    emit(state.copyWith(isVisible: true));
  }

  /// Handler for hiding bottom navigation
  void _onHideBottomNav(HideBottomNav event, Emitter<BottomNavVisibilityState> emit) {
    emit(state.copyWith(isVisible: false));
  }
}

