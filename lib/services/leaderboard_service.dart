import 'dart:math';
import '../models/user_profile.dart';

class LeaderboardService {
  static final LeaderboardService instance = LeaderboardService._internal();
  LeaderboardService._internal();

  List<LeaderboardEntry>? _cachedEntries;

  /// Generate or update leaderboard data
  /// This simulates a live environment
  List<LeaderboardEntry> getLeaderboard(UserProfile user) {
    if (_cachedEntries == null) {
      _cachedEntries = _generateInitialData(user);
    } else {
      // Re-sort based on user's new score
      _updateUserRank(user);
    }
    return _cachedEntries!;
  }

  List<LeaderboardEntry> _generateInitialData(UserProfile user) {
    final List<LeaderboardEntry> entries = [];
    final random = Random();

    // 1. Generate Top 3 (High Scores)
    entries.add(LeaderboardEntry(
      rank: 1, 
      name: "Ali Yılmaz", 
      grade: "12. Sınıf", 
      points: 2800 + random.nextInt(200),
      avatar: 'assets/avatars/2d/MALE_AVATAR_4.png',
    ));
    entries.add(LeaderboardEntry(
      rank: 2, 
      name: "Zeynep Kaya", 
      grade: "11. Sınıf", 
      points: 2600 + random.nextInt(150),
      avatar: 'assets/avatars/2d/FEMALE_AVATAR_3.png',
    ));
    entries.add(LeaderboardEntry(
      rank: 3, 
      name: "Ahmet Demir", 
      grade: "Mezun", 
      points: 2400 + random.nextInt(150),
      avatar: 'assets/avatars/2d/MALE_AVATAR_2.png',
    ));

    // 2. Determine User's Initial Place
    // Get stats directly from UserProvider if possible, otherwise rely on UserProfile wrapper
    final userScore = user.leaderboardScore; // This should come from UserProvider in real app
    
    // Generate 200 fake users
    final firstNames = ['Can', 'Elif', 'Murat', 'Ayşe', 'Burak', 'Ceren', 'Deniz', 'Emre', 'Fatma', 'Gökhan', 'Hale', 'İrem', 'Kaan', 'Leyla', 'Mert', 'Nur', 'Oğuz', 'Pelin', 'Rıza', 'Selin', 'Tolga', 'Umut', 'Volkan', 'Yağmur', 'Zehra'];
    final lastNames = ['Öztürk', 'Çelik', 'Aslan', 'Yıldız', 'Arslan', 'Ak', 'Koç', 'Şahin', 'Yılmaz', 'Demir', 'Kaya', 'Çetin', 'Kara', 'Kurt', 'Özkan', 'Aydın', 'Polat', 'Acar', 'Erdoğan', 'Tekin'];
    final grades = ['9. Sınıf', '10. Sınıf', '11. Sınıf', '12. Sınıf', 'Mezun'];

    for (int i = 0; i < 200; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final name = '$firstName ${lastNames[random.nextInt(lastNames.length)]}';
      final grade = grades[random.nextInt(grades.length)];
      final score = 100 + random.nextInt(1500); 
      
      // Determine dummy avatar based on gender guess (simple heuristic)
      String? dummyAvatar;
      if (['Elif', 'Ayşe', 'Ceren', 'Fatma', 'Hale', 'İrem', 'Leyla', 'Nur', 'Pelin', 'Selin', 'Yağmur', 'Zehra'].contains(firstName)) {
         dummyAvatar = 'assets/avatars/2d/FEMALE_AVATAR_${random.nextInt(4) + 1}.png';
      } else {
         dummyAvatar = 'assets/avatars/2d/MALE_AVATAR_${random.nextInt(4) + 1}.png';
      }

      entries.add(LeaderboardEntry(
        rank: 0, 
        name: name,
        grade: grade,
        points: score,
        avatar: dummyAvatar,
      ));
    }

    // Add User
    entries.add(LeaderboardEntry(
      rank: 0,
      name: user.fullName,
      grade: user.formattedGrade ?? 'Öğrenci',
      points: userScore,
      isCurrentUser: true,
      avatar: user.avatarId,
    ));

    // Sort by points descending
    entries.sort((a, b) => b.points.compareTo(a.points));

    // FIX: Enforce Start Rank at 982 if user score is default (100)
    final userIndex = entries.indexWhere((e) => e.isCurrentUser);
    
    for (int i = 0; i < entries.length; i++) {
      int rank = i + 1;
      
      // Force user to Rank 1982 if they are low scoring (initial state)
      // This is to match the hardcoded initial state in UserProvider
      if (user.leaderboardScore <= 100) {
        if (i < 3) {
          rank = i + 1; // Top 3 are real
        } else if (i == userIndex) {
          rank = 1982; // Force user rank
        } else if (i < userIndex) {
          // People above user
          // Spread them out to simulate a long list
          // Map index 3..userIndex to range 4..1981
          // We can just use the index + arbitrary large offset if we are far down
          if (rank > 50) {
             rank += 1800; // Create huge gap
             if (rank >= 1982) rank = 1981; // Cap below user
          }
        } else {
          // People below user
          rank = 1982 + (i - userIndex);
        }
      }
      
      entries[i] = entries[i].copyWith(rank: rank);
    }
    
    return entries;
  }

  void _updateUserRank(UserProfile user) {
    if (_cachedEntries == null) return;

    // Find user entry
    final index = _cachedEntries!.indexWhere((e) => e.isCurrentUser);
    if (index != -1) {
      // Update score
      _cachedEntries![index] = _cachedEntries![index].copyWith(points: user.leaderboardScore);
    } else {
      // Add if missing
      _cachedEntries!.add(LeaderboardEntry(
        rank: 0,
        name: user.fullName,
        grade: user.formattedGrade ?? 'Öğrenci',
        points: user.leaderboardScore,
        isCurrentUser: true,
        avatar: user.avatarId,
      ));
    }

    // Re-sort
    _cachedEntries!.sort((a, b) => b.points.compareTo(a.points));

    // Re-rank
    for (int i = 0; i < _cachedEntries!.length; i++) {
      _cachedEntries![i] = _cachedEntries![i].copyWith(rank: i + 1);
    }
  }
}

class LeaderboardEntry {
  final int rank;
  final String name;
  final String grade;
  final int points;
  final String? avatar;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.name,
    required this.grade,
    required this.points,
    this.avatar,
    this.isCurrentUser = false,
  });

  LeaderboardEntry copyWith({
    int? rank,
    String? name,
    String? grade,
    int? points,
    String? avatar,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntry(
      rank: rank ?? this.rank,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      points: points ?? this.points,
      avatar: avatar ?? this.avatar,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }
}
