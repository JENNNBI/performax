import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/user_service.dart';
import 'user_profile_event.dart';
import 'user_profile_state.dart';

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final UserService _userService;

  UserProfileBloc({UserService? userService})
      : _userService = userService ?? UserService(),
        super(const UserProfileInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<RefreshUserProfile>(_onRefreshUserProfile);
    on<ClearUserProfile>(_onClearUserProfile);
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(const UserProfileLoading());
      
      // Force refresh from server to ensure we get fresh data after login
      // This is especially important when switching between user accounts
      final profile = await _userService.getCurrentUserProfile(forceRefresh: true);
      
      if (profile != null) {
        emit(UserProfileLoaded(
          userProfile: profile,
          userData: profile.toMap(),
        ));
        
        debugPrint('✅ UserProfileBloc: Profile loaded for ${profile.displayName}');
        debugPrint('   User ID: ${profile.userId}');
        if (profile.school != null) {
          debugPrint('   School: ${profile.school}');
        }
        if (profile.gradeLevel != null) {
          debugPrint('   Grade: ${profile.gradeLevel}');
        }
      } else {
        emit(const UserProfileGuest());
        debugPrint('⚠️ UserProfileBloc: No profile found, user is guest');
      }
    } catch (e) {
      emit(UserProfileError('Failed to load profile: $e'));
      debugPrint('❌ UserProfileBloc: Error loading profile: $e');
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(UserProfileLoaded(
        userProfile: event.userProfile,
        userData: event.userProfile.toMap(),
      ));
      
      debugPrint('✅ UserProfileBloc: Profile updated for ${event.userProfile.displayName}');
    } catch (e) {
      debugPrint('❌ UserProfileBloc: Error updating profile: $e');
    }
  }

  Future<void> _onRefreshUserProfile(
    RefreshUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    // Reload profile from Firebase
    add(const LoadUserProfile());
  }

  Future<void> _onClearUserProfile(
    ClearUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    emit(const UserProfileInitial());
    debugPrint('✅ UserProfileBloc: Profile cleared');
  }
}

