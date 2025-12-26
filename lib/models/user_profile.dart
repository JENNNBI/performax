import 'avatar.dart';

/// User Profile Model for AI Context
/// 
/// Contains student-specific data that the AI Assistant uses
/// to provide personalized, contextual responses.
class UserProfile {
  final String userId;
  final String fullName;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? school;
  final String? gradeLevel;
  final String? studentClass;
  final String? studentNumber;
  final String? city;
  final String? district;
  final String? gender;  // 'male' or 'female'
  final String? avatarId; // Avatar identifier
  final String? phoneNumber; // User's phone number (E.164 format)
  final bool isPhoneVerified; // Whether phone number has been verified via OTP
  final int rocketCurrency; // In-game Rocket currency balance (Spendable)
  final int leaderboardScore; // Total accumulated rockets (Ranking)
  final bool isGuest;
  final String? studyField; // 'Sayısal', 'Eşit Ağırlık', 'Sözel'
  
  UserProfile({
    required this.userId,
    required this.fullName,
    this.firstName,
    this.lastName,
    required this.email,
    this.school,
    this.gradeLevel,
    this.studentClass,
    this.studentNumber,
    this.city,
    this.district,
    this.gender,
    this.avatarId,
    this.phoneNumber,
    this.isPhoneVerified = false,
    this.rocketCurrency = 0, // Default initial balance
    this.leaderboardScore = 100, // Default initial ranking score
    this.isGuest = false,
    this.studyField,
  });

  /// Create UserProfile from Firestore document
  factory UserProfile.fromMap(String userId, Map<String, dynamic> data) {
    // Extract school name from institution object or direct school field
    String? schoolName;
    final institutionData = data['institution'];
    if (institutionData != null) {
      if (institutionData is Map<String, dynamic>) {
        schoolName = institutionData['name'] as String?;
      } else if (institutionData is String) {
        schoolName = institutionData;
      }
    }
    // Fallback to 'school' field if exists
    schoolName ??= data['school'] as String?;
    
    // Extract avatar ID from avatar field
    String? avatarId;
    final avatarData = data['avatar'];
    if (avatarData is Map<String, dynamic>) {
      avatarId = avatarData['id'] as String?;
    } else if (avatarData is String) {
      avatarId = avatarData;
    }
    
    return UserProfile(
      userId: userId,
      fullName: data['fullName'] ?? data['name'] ?? 'Öğrenci',
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'] ?? '',
      school: schoolName,
      gradeLevel: data['gradeLevel'] ?? data['grade'] ?? data['class'],
      studentClass: data['class'],
      studentNumber: data['studentNumber'],
      city: data['city'],
      district: data['district'],
      gender: data['gender'],
      avatarId: avatarId,
      phoneNumber: data['phoneNumber'] as String?,
      isPhoneVerified: data['isPhoneVerified'] as bool? ?? false,
      rocketCurrency: data['rocketCurrency'] ?? 100, // Default to 100 if not set
      leaderboardScore: data['leaderboardScore'] ?? 100, // Default 100
      isGuest: false,
      studyField: data['studyField'] as String?,
    );
  }

  /// Create guest user profile
  factory UserProfile.guest() {
    return UserProfile(
      userId: 'guest',
      fullName: 'Misafir Kullanıcı',
      email: 'guest@user.com',
      isGuest: true,
    );
  }

  /// Get display name (first name or full name)
  String get displayName => firstName ?? fullName.split(' ').first;
  
  /// Get avatar object
  Avatar get avatar => Avatar.getById(avatarId);

  /// Get formatted grade level (e.g., "9. Sınıf")
  String? get formattedGrade {
    if (gradeLevel == null) return null;
    // Handle different grade formats
    final grade = gradeLevel!.replaceAll(RegExp(r'[^\d]'), '');
    if (grade.isEmpty) return gradeLevel;
    return '$grade. Sınıf';
  }

  /// Build context string for AI
  String buildAIContext() {
    final contextParts = <String>[];
    
    contextParts.add('Öğrenci: $fullName');
    
    if (school != null && school!.isNotEmpty) {
      contextParts.add('Okul: $school');
    }
    
    if (gradeLevel != null && gradeLevel!.isNotEmpty) {
      contextParts.add('Sınıf: ${formattedGrade ?? gradeLevel}');
    }
    
    if (studentClass != null && studentClass!.isNotEmpty) {
      contextParts.add('Şube: $studentClass');
    }
    
    if (city != null && city!.isNotEmpty) {
      if (district != null && district!.isNotEmpty) {
        contextParts.add('Konum: $district, $city');
      } else {
        contextParts.add('Konum: $city');
      }
    }
    
    return contextParts.join(' | ');
  }

  /// Get abbreviated context for short displays
  String getShortContext() {
    final parts = <String>[];
    
    if (gradeLevel != null) {
      parts.add(formattedGrade ?? gradeLevel!);
    }
    
    if (school != null && school!.isNotEmpty) {
      // Shorten school name if too long
      final schoolName = school!.length > 30 
          ? '${school!.substring(0, 30)}...' 
          : school!;
      parts.add(schoolName);
    }
    
    return parts.join(' - ');
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'school': school,
      'gradeLevel': gradeLevel,
      'class': studentClass,
      'studentNumber': studentNumber,
      'city': city,
      'district': district,
      'gender': gender,
      'avatarId': avatarId,
      'phoneNumber': phoneNumber,
      'isPhoneVerified': isPhoneVerified,
      'rocketCurrency': rocketCurrency,
      'leaderboardScore': leaderboardScore,
      'isGuest': isGuest,
      'studyField': studyField,
    };
  }

  @override
  String toString() => 'UserProfile(${buildAIContext()})';

  UserProfile copyWith({
    String? userId,
    String? fullName,
    String? firstName,
    String? lastName,
    String? email,
    String? school,
    String? gradeLevel,
    String? studentClass,
    String? studentNumber,
    String? city,
    String? district,
    String? gender,
    String? avatarId,
    String? phoneNumber,
    bool? isPhoneVerified,
    int? rocketCurrency,
    int? leaderboardScore,
    bool? isGuest,
    String? studyField,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      school: school ?? this.school,
      gradeLevel: gradeLevel ?? this.gradeLevel,
      studentClass: studentClass ?? this.studentClass,
      studentNumber: studentNumber ?? this.studentNumber,
      city: city ?? this.city,
      district: district ?? this.district,
      gender: gender ?? this.gender,
      avatarId: avatarId ?? this.avatarId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      rocketCurrency: rocketCurrency ?? this.rocketCurrency,
      leaderboardScore: leaderboardScore ?? this.leaderboardScore,
      isGuest: isGuest ?? this.isGuest,
      studyField: studyField ?? this.studyField,
    );
  }
}

