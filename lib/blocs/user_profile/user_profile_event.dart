import 'package:equatable/equatable.dart';
import '../../models/user_profile.dart';

abstract class UserProfileEvent extends Equatable {
  const UserProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load user profile from Firebase
class LoadUserProfile extends UserProfileEvent {
  const LoadUserProfile();
}

/// Event to update user profile
class UpdateUserProfile extends UserProfileEvent {
  final UserProfile userProfile;

  const UpdateUserProfile(this.userProfile);

  @override
  List<Object?> get props => [userProfile];
}

/// Event to refresh user profile (reload from Firebase)
class RefreshUserProfile extends UserProfileEvent {
  const RefreshUserProfile();
}

/// Event to clear user profile (on logout)
class ClearUserProfile extends UserProfileEvent {
  const ClearUserProfile();
}

