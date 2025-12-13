import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

abstract class UserProfileState extends Equatable {
  const UserProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state - no profile loaded yet
class UserProfileInitial extends UserProfileState {
  const UserProfileInitial();
}

/// Loading state - fetching profile from Firebase
class UserProfileLoading extends UserProfileState {
  const UserProfileLoading();
}

/// Loaded state - profile successfully loaded
class UserProfileLoaded extends UserProfileState {
  final UserProfile userProfile;
  final Map<String, dynamic> userData; // Legacy compatibility

  const UserProfileLoaded({
    required this.userProfile,
    required this.userData,
  });

  @override
  List<Object?> get props => [userProfile, userData];

  /// Check if user is guest
  bool get isGuest => userProfile.isGuest;

  /// Get display name
  String get displayName => userProfile.displayName;

  /// Get school or default text
  String get schoolDisplay => userProfile.school ?? 'Belirtilmemiş';

  /// Get grade level or default text
  String get gradeDisplay => userProfile.formattedGrade ?? 'Belirtilmemiş';
}

/// Error state - failed to load profile
class UserProfileError extends UserProfileState {
  final String message;

  const UserProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Guest state - user is using app without login
class UserProfileGuest extends UserProfileState {
  const UserProfileGuest();
}

