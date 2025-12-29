import '../models/playlist_model.dart';

/// Playlist Configuration Service
/// Manages playlist data for different subjects/categories
class PlaylistConfigService {
  /// Matematik Problemler Playlists
  /// Configuration for "Matematik > Problemler" category
  static final List<PlaylistModel> mathProblemPlaylists = [
    PlaylistModel(
      title: "2025 Problemler Kampı",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLHk4O6pXTZyMWD71RVkNOvMBFO-RDH_KW",
      description: "Kapsamlı problemler kampı içeriği",
      thumbnailUrl: "https://i.ytimg.com/vi/rU_HpnKjYlw/hqdefault.jpg", // First video thumbnail (hqdefault - guaranteed to exist)
    ),
    // More playlists can be added here later
  ];

  /// Matematik Level-to-Playlist Mapping
  /// Maps specific Matematik levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API
  static final Map<String, PlaylistModel> mathLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Matematik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLoxGVWRHfg5i6hhtSVjNoYDGfVYdn6nP2",
      description: "9. Sınıf Matematik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/IrmzvwKkxI8/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Matematik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLoxGVWRHfg5gqXWMQjnbdZJ4f-XjxNhnV",
      description: "10. Sınıf Matematik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/NPwRTRbu4Rw/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Matematik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLSYiXUktJiZflPeFBCpOgICCfRiX2_ik9",
      description: "11. Sınıf Matematik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/j19HFSy2TyA/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Matematik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL7yyuqSjyhKHtSPDq2lhlAqXRkH-rEdrG",
      description: "TYT Matematik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/3NTbgdBN_As/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Matematik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL7yyuqSjyhKG3O-dHBOE0iZtA3LWmPW2g",
      description: "AYT Matematik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/l6qRofgQ9XM/hqdefault.jpg",
    ),
  };

  /// Türkçe Level-to-Playlist Mapping
  /// Maps specific Türkçe levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API
  static final Map<String, PlaylistModel> turkceLevelPlaylists = {
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Türkçe",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLL4Uzg_MGO2J74Fma5G2VblIJV21t5s9W",
      description: "TYT Türkçe konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/eua00_dyw4o/hqdefault.jpg",
    ),
    'Paragraf': PlaylistModel(
      title: "Paragraf",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLQFPdCXclF1wwDjjGTYuYTRPD0U6TwZXx",
      description: "Paragraf konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/WAAPmShT5nA/hqdefault.jpg",
    ),
  };

  /// Geometri Level-to-Playlist Mapping
  /// Maps specific Geometri levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API
  static final Map<String, PlaylistModel> geometriLevelPlaylists = {
    // Combined Exam Type
    'TYT-AYT': PlaylistModel(
      title: "TYT-AYT Geometri",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLPABJcnKQ9ads88fkG7A7bFnT60aOzB7H",
      description: "TYT-AYT Geometri konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/W7tCuHXMmWw/hqdefault.jpg",
    ),
  };

  /// Fizik Level-to-Playlist Mapping
  /// Maps specific Fizik levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API (VIP Fizik, Altuğ Güneş, Özcan Aykın)
  static final Map<String, PlaylistModel> fizikLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Fizik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLwyfvkhKMmwpfLy-4728YZjjgyNnZ5u5U",
      description: "9. Sınıf Fizik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/odLQ1IQ7INY/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Fizik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLwyfvkhKMmwptZrdVBenArZzARv-cK4Ju",
      description: "10. Sınıf Fizik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/uMkwo5MtBdo/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Fizik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLw6C1pT6u5096bCqsbtB2NsWcHZapr-o7",
      description: "11. Sınıf Fizik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/4jmpk9jhnos/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Fizik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLhhV4F6NB0-uEPdZncMf_qb0tSKyBM-Lf",
      description: "TYT Fizik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/_2tScyttE88/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Fizik",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLhhV4F6NB0-tU__PwCFhnaK-Gg_I3JG_4",
      description: "AYT Fizik konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/kDtBf9av1PU/hqdefault.jpg",
    ),
  };

  /// Kimya Level-to-Playlist Mapping
  /// Maps specific Kimya levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API (Kimya Adası, Meskalin Kimya, Görkem Şahin)
  static final Map<String, PlaylistModel> kimyaLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Kimya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLd4M-84iDGShHLxJkJTnxRvWCTTcMzfPN",
      description: "9. Sınıf Kimya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/y7nSOydKJW8/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Kimya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLd4M-84iDGSjMcOdmVuhFBotUnUj8_tO6",
      description: "10. Sınıf Kimya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/baVzqaykBwE/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Kimya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLB0hn7Hw33ss3fSssPG_J69QBmAotbd_o",
      description: "11. Sınıf Kimya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/umS2lWBbVJk/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Kimya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLBals97P4r_YU0m0vJQSM_MJzM-k0p1Vu",
      description: "TYT Kimya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/HhZOAH61fng/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Kimya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLB0hn7Hw33ss5-gD7SwIcCaN8iyIEk2oK",
      description: "AYT Kimya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/d--3Tb5pBcM/hqdefault.jpg",
    ),
  };

  /// Biyoloji Level-to-Playlist Mapping
  /// Maps specific Biyoloji levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API (Dr. Biyoloji, FUNDAmentals Biyoloji, Biosem)
  static final Map<String, PlaylistModel> biyolojiLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Biyoloji",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLPRCxOxVF0fKDuGAhHStlIXHEBWwQdWsX",
      description: "9. Sınıf Biyoloji konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/wWo-LXofTxc/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Biyoloji",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLPRCxOxVF0fJe2wG1c7AYm_Tu1PEpDGWM",
      description: "10. Sınıf Biyoloji konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/noTaNJcA2O8/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Biyoloji",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLAdrMA6Aq8IkQi5lheF27Ts12ITzc_xzv",
      description: "11. Sınıf Biyoloji konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/-I5xLlpZjTU/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Biyoloji",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLPRCxOxVF0fKDuGAhHStlIXHEBWwQdWsX",
      description: "TYT Biyoloji konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/wWo-LXofTxc/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Biyoloji",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLqLwBmByktJXYLOn2HhcXWpIH0fuIa_pk",
      description: "AYT Biyoloji konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/4gbxoMHYNJ8/hqdefault.jpg",
    ),
  };

  /// Felsefe Level-to-Playlist Mapping
  /// Maps specific Felsefe levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API
  static final Map<String, PlaylistModel> felsefeLevelPlaylists = {
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Felsefe",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL4P7Q5QUoe-iodiVl_7z0IinPm4weN4dn",
      description: "TYT Felsefe konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/g2CatlHZ5Lw/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Felsefe",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL4P7Q5QUoe-hsbb4IgekcHiDCAMP-l9kI",
      description: "AYT Felsefe konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/cLveuoLjgzM/hqdefault.jpg",
    ),
  };

  /// Coğrafya Level-to-Playlist Mapping
  /// Maps specific Coğrafya levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API (Coğrafyanın Kodları, Yavuz Tuna Coğrafya)
  static final Map<String, PlaylistModel> cografyaLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Coğrafya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLQRIAABBNZ6yDkVvimB8TLGjmmRlecDYB",
      description: "9. Sınıf Coğrafya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/bP1g7A_faD8/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Coğrafya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLQRIAABBNZ6wAWmlK6_ak82DiFhLatVum",
      description: "10. Sınıf Coğrafya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/tRX2DZjJXXA/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Coğrafya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLnBnugScc-7LiD4PNv5NbbJbNdGToWKMf",
      description: "11. Sınıf Coğrafya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/LQhLcXoAjG0/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Coğrafya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLQRIAABBNZ6ybTrF2Ee43FykBG_-zBxp7",
      description: "TYT Coğrafya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/adR9jj3Y64Y/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Coğrafya",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLnBnugScc-7LeZJX315_SnVZEJzUh4CLt",
      description: "AYT Coğrafya konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/Hi7vOmknvC8/hqdefault.jpg",
    ),
  };

  /// Tarih Level-to-Playlist Mapping
  /// Maps specific Tarih levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API (Benim Hocam, Sosyal Kale)
  static final Map<String, PlaylistModel> tarihLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf Tarih",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLRbyTgiOSh9nObmz1E-Pm9YAVAhkbaeX8",
      description: "9. Sınıf Tarih konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/SQup3Q1OWIg/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf Tarih",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLRbyTgiOSh9nalZvTd_P05z8Q4Jn0F3KD",
      description: "10. Sınıf Tarih konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/asBN4diTnL4/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf Tarih",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLVYRYHhcP7db7I_WBauONoh1gB9aTBZqF",
      description: "11. Sınıf Tarih konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/s8rxJVJowhM/hqdefault.jpg",
    ),
    // Exam Types
    'TYT': PlaylistModel(
      title: "TYT Tarih",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLVYRYHhcP7dbEfd85NWW1EZ2TNd04KuKH",
      description: "TYT Tarih konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/iOJonOCej8I/hqdefault.jpg",
    ),
    'AYT': PlaylistModel(
      title: "AYT Tarih",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLRbyTgiOSh9nRfPfKGP0ataXT5vDQjnNf",
      description: "AYT Tarih konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/dYk8jcL6LN4/hqdefault.jpg",
    ),
  };

  /// TDE (Türk Dili ve Edebiyatı) Level-to-Playlist Mapping
  /// Maps specific TDE levels to their corresponding YouTube playlists
  /// Channel names are dynamically fetched from YouTube API
  static final Map<String, PlaylistModel> tdeLevelPlaylists = {
    // Grade Levels
    '9. Sınıf': PlaylistModel(
      title: "9. Sınıf TDE",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL5mDkhVq27AHFioRUnUkxU1jKZU5LrjsU",
      description: "9. Sınıf Türk Dili ve Edebiyatı konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/6gIWuPlmuEs/hqdefault.jpg",
    ),
    '10. Sınıf': PlaylistModel(
      title: "10. Sınıf TDE",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL5mDkhVq27AEANU74vofS_nhFFzIGThA6",
      description: "10. Sınıf Türk Dili ve Edebiyatı konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/-2FQt3G2yWg/hqdefault.jpg",
    ),
    '11. Sınıf': PlaylistModel(
      title: "11. Sınıf TDE",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PL5mDkhVq27AFrbLU7Hpys-TPAzfJ64p_b",
      description: "11. Sınıf Türk Dili ve Edebiyatı konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/GxYvmxb1ZxU/hqdefault.jpg",
    ),
    // Exam Types
    'AYT': PlaylistModel(
      title: "AYT TDE",
      // channelName: Dynamically fetched from YouTube API
      playlistId: "PLL4Uzg_MGO2KLvMMgvlyvZtpyg0khfaw6",
      description: "AYT Türk Dili ve Edebiyatı konu anlatımları",
      thumbnailUrl: "https://i.ytimg.com/vi/z7gHRy-OXLM/hqdefault.jpg",
    ),
  };

  /// Get playlists for a specific subject and category
  static List<PlaylistModel> getPlaylistsForCategory({
    required String subject,
    required String category,
  }) {
    if (subject == 'Matematik' && category == 'Problemler') {
      return mathProblemPlaylists;
    }
    return [];
  }

  /// Get playlist for a specific subject level
  static PlaylistModel? getPlaylistForLevel({
    required String subject,
    required String level,
  }) {
    if (subject == 'Matematik') {
      return mathLevelPlaylists[level];
    } else if (subject == 'Türkçe') {
      return turkceLevelPlaylists[level];
    } else if (subject == 'Edebiyat' || subject == 'TDE') {
      // TDE (Türk Dili ve Edebiyatı) uses the same key as Edebiyat
      return tdeLevelPlaylists[level];
    } else if (subject == 'Geometri') {
      return geometriLevelPlaylists[level];
    } else if (subject == 'Fizik') {
      return fizikLevelPlaylists[level];
    } else if (subject == 'Kimya') {
      return kimyaLevelPlaylists[level];
    } else if (subject == 'Biyoloji') {
      return biyolojiLevelPlaylists[level];
    } else if (subject == 'Felsefe') {
      return felsefeLevelPlaylists[level];
    } else if (subject == 'Coğrafya') {
      return cografyaLevelPlaylists[level];
    } else if (subject == 'Tarih') {
      return tarihLevelPlaylists[level];
    }
    return null;
  }

  /// Get all playlists for a specific subject level
  static List<PlaylistModel> getPlaylistsForLevel({
    required String subject,
    required String level,
  }) {
    final playlist = getPlaylistForLevel(subject: subject, level: level);
    if (playlist != null) {
      return [playlist];
    }
    return [];
  }
}
