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
    
    // Auto-load cached profile on bloc creation for instant UI display
    // This prevents empty fields on app restart
    // Dispatch LoadUserProfile which will load from cache first
    add(const LoadUserProfile());
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      emit(const UserProfileLoading());
      
      // Step 1: Load from cache first (instant display)
      // This prevents empty fields on app restart
      final cachedProfile = await _userService.getCurrentUserProfile(
        forceRefresh: false,
        useCache: true,
      );
      
      if (cachedProfile != null) {
        // Emit cached data immediately for instant UI update
        emit(UserProfileLoaded(
          userProfile: cachedProfile,
          userData: cachedProfile.toMap(),
        ));
        
        debugPrint('✅ UserProfileBloc: Profile loaded from cache for ${cachedProfile.displayName}');
        
        // Step 2: Refresh from server in background (non-blocking)
        // This ensures we have the latest data, but doesn't block UI
        _refreshProfileFromServer(emit).catchError((e) {
          debugPrint('⚠️ UserProfileBloc: Background refresh failed: $e');
          // Don't emit error - cached data is still valid
        });
      } else {
        // No cache available, fetch from server
        final profile = await _userService.getCurrentUserProfile(forceRefresh: true);
        
        if (profile != null) {
          emit(UserProfileLoaded(
            userProfile: profile,
            userData: profile.toMap(),
          ));
          
          debugPrint('✅ UserProfileBloc: Profile loaded from server for ${profile.displayName}');
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
      }
    } catch (e) {
      // Try to fallback to cache even on error
      try {
        final cachedProfile = await _userService.getCurrentUserProfile(
          forceRefresh: false,
          useCache: true,
        );
        if (cachedProfile != null) {
          emit(UserProfileLoaded(
            userProfile: cachedProfile,
            userData: cachedProfile.toMap(),
          ));
          debugPrint('✅ UserProfileBloc: Using cached profile after error');
          return;
        }
      } catch (_) {
        // Ignore cache errors
      }
      
      emit(UserProfileError('Failed to load profile: $e'));
      debugPrint('❌ UserProfileBloc: Error loading profile: $e');
    }
  }
  
  /// Refresh profile from server in background
  /// Updates state if new data is different from cached data
  Future<void> _refreshProfileFromServer(Emitter<UserProfileState> emit) async {
    try {
      final profile = await _userService.getCurrentUserProfile(forceRefresh: true);
      
      if (profile != null) {
        // Only emit if state is still valid and we're still mounted
        emit(UserProfileLoaded(
          userProfile: profile,
          userData: profile.toMap(),
        ));
        
        debugPrint('✅ UserProfileBloc: Profile refreshed from server for ${profile.displayName}');
      }
    } catch (e) {
      debugPrint('⚠️ UserProfileBloc: Background refresh error: $e');
      // Don't emit error - cached data is still valid
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    try {
      // Update state
      emit(UserProfileLoaded(
        userProfile: event.userProfile,
        userData: event.userProfile.toMap(),
      ));
      
      // Cache is automatically updated by UserService.updateUserProfile()
      debugPrint('✅ UserProfileBloc: Profile updated for ${event.userProfile.displayName}');
    } catch (e) {
      debugPrint('❌ UserProfileBloc: Error updating profile: $e');
    }
  }

  Future<void> _onRefreshUserProfile(
    RefreshUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    // Reload profile from Firebase with force refresh
    // This bypasses cache to get latest data
    try {
      emit(const UserProfileLoading());
      
      final profile = await _userService.getCurrentUserProfile(forceRefresh: true);
      
      if (profile != null) {
        emit(UserProfileLoaded(
          userProfile: profile,
          userData: profile.toMap(),
        ));
        debugPrint('✅ UserProfileBloc: Profile refreshed for ${profile.displayName}');
      } else {
        emit(const UserProfileGuest());
      }
    } catch (e) {
      // Try cache fallback
      final cachedProfile = await _userService.getCurrentUserProfile(
        forceRefresh: false,
        useCache: true,
      );
      if (cachedProfile != null) {
        emit(UserProfileLoaded(
          userProfile: cachedProfile,
          userData: cachedProfile.toMap(),
        ));
      } else {
        emit(UserProfileError('Failed to refresh profile: $e'));
      }
    }
  }

  Future<void> _onClearUserProfile(
    ClearUserProfile event,
    Emitter<UserProfileState> emit,
  ) async {
    // Clear cached profile when logging out
    await UserService.clearAllUserData();
    emit(const UserProfileInitial());
    debugPrint('✅ UserProfileBloc: Profile cleared and cache removed');
  }
}

