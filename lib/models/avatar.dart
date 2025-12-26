/// Avatar Model
/// Represents user avatars with 2D and 3D variants
class Avatar {
  final String id;
  final String gender; // 'male' or 'female'
  final String displayName;
  final String bust2DPath; // Path to 2D bust-level image
  final String? full3DPath; // Path to 3D model (optional for MVP)
  final String skinTone; // Description for reference
  final String hairStyle; // Description for reference

  const Avatar({
    required this.id,
    required this.gender,
    required this.displayName,
    required this.bust2DPath,
    this.full3DPath,
    required this.skinTone,
    required this.hairStyle,
  });

  /// Predefined avatar collection - 8 avatars with diverse phenotypes
  /// Using abstract/non-standard identifiers instead of real names
  static const List<Avatar> allAvatars = [
    // Male Avatars (4 variants)
    Avatar(
      id: 'male_1',
      gender: 'male',
      displayName: 'Avatar A',
      bust2DPath: 'assets/avatars/2d/MALE_AVATAR_1.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Light',
      hairStyle: 'Short Brown',
    ),
    Avatar(
      id: 'male_2',
      gender: 'male',
      displayName: 'Avatar B',
      bust2DPath: 'assets/avatars/2d/MALE_AVATAR_2.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Medium/Olive',
      hairStyle: 'Styled Black',
    ),
    Avatar(
      id: 'male_3',
      gender: 'male',
      displayName: 'Avatar C',
      bust2DPath: 'assets/avatars/2d/MALE_AVATAR_3.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Dark',
      hairStyle: 'Short Curly',
    ),
    Avatar(
      id: 'male_4',
      gender: 'male',
      displayName: 'Avatar D',
      bust2DPath: 'assets/avatars/2d/MALE_AVATAR_4.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'East Asian',
      hairStyle: 'Straight Black',
    ),

    // Female Avatars (4 variants)
    Avatar(
      id: 'female_1',
      gender: 'female',
      displayName: 'Avatar E',
      bust2DPath: 'assets/avatars/2d/FEMALE_AVATAR_1.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Light',
      hairStyle: 'Long Brown Ponytail',
    ),
    Avatar(
      id: 'female_2',
      gender: 'female',
      displayName: 'Avatar F',
      bust2DPath: 'assets/avatars/2d/FEMALE_AVATAR_2.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Medium/Olive',
      hairStyle: 'Medium Black with Hijab',
    ),
    Avatar(
      id: 'female_3',
      gender: 'female',
      displayName: 'Avatar G',
      bust2DPath: 'assets/avatars/2d/FEMALE_AVATAR_3.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'Dark',
      hairStyle: 'Natural Curls',
    ),
    Avatar(
      id: 'female_4',
      gender: 'female',
      displayName: 'Avatar H',
      bust2DPath: 'assets/avatars/2d/FEMALE_AVATAR_4.png',
      full3DPath: 'assets/avatars/3d/scene_with_textures.glb',
      skinTone: 'East Asian',
      hairStyle: 'Long Straight Black',
    ),
  ];

  /// Get avatar by ID
  static Avatar getById(String? id) {
    if (id == null) return allAvatars[0];
    return allAvatars.firstWhere(
      (avatar) => avatar.id == id,
      orElse: () => allAvatars[0],
    );
  }

  /// Get avatars by gender
  static List<Avatar> getByGender(String gender) {
    return allAvatars.where((a) => a.gender == gender).toList();
  }

  /// Get default avatar based on gender
  static Avatar getDefaultByGender(String? gender) {
    if (gender == 'female') {
      return allAvatars.firstWhere((a) => a.id == 'female_1');
    }
    return allAvatars.firstWhere((a) => a.id == 'male_1');
  }

  @override
  String toString() => 'Avatar($id, $displayName, $gender)';
}
