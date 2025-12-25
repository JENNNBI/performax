import 'package:shared_preferences/shared_preferences.dart';

class LocalizationService {
  static const String _languageKey = 'selected_language';
  static String _currentLanguage = 'tr';

  static String get currentLanguage => _currentLanguage;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_languageKey) ?? 'tr';
  }

  static Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // Common UI Elements
    'back': {'tr': 'Geri', 'en': 'Back'},
    'next': {'tr': 'İleri', 'en': 'Next'},
    'finish': {'tr': 'Bitir', 'en': 'Finish'},
    'continue': {'tr': 'Devam Et', 'en': 'Continue'},
    'skip': {'tr': 'Geç', 'en': 'Skip'},
    'done': {'tr': 'Tamamla', 'en': 'Done'},
    'ok': {'tr': 'Tamam', 'en': 'OK'},
    'yes': {'tr': 'Evet', 'en': 'Yes'},
    'no': {'tr': 'Hayır', 'en': 'No'},
    'loading': {'tr': 'Yükleniyor...', 'en': 'Loading...'},
    'error': {'tr': 'Hata', 'en': 'Error'},
    'success': {'tr': 'Başarılı', 'en': 'Success'},
    'warning': {'tr': 'Uyarı', 'en': 'Warning'},
    
    // First Screen
    'welcome_to_performax': {'tr': 'Performax\'a Hoş Geldiniz', 'en': 'Welcome to Performax'},
    'get_started': {'tr': 'Başlayın', 'en': 'Get Started'},
    'performax_description': {'tr': 'Modern eğitim platformu ile öğrenme deneyiminizi geliştirin', 'en': 'Enhance your learning experience with our modern education platform'},
    
    // Login & Registration
    'login': {'tr': 'Giriş Yap', 'en': 'Login'},
    'register': {'tr': 'Kayıt Ol', 'en': 'Register'},
    'guest_login': {'tr': 'Misafir Olarak Devam Et', 'en': 'Continue as Guest'},
    'email': {'tr': 'E-posta', 'en': 'Email'},
    'password': {'tr': 'Şifre', 'en': 'Password'},
    'confirm_password': {'tr': 'Şifre Tekrar', 'en': 'Confirm Password'},
    'full_name': {'tr': 'Ad Soyad', 'en': 'Full Name'},
    'class': {'tr': 'Sınıf', 'en': 'Class'},
    'institution': {'tr': 'Okul/Kurum', 'en': 'School/Institution'},
    'birth_date': {'tr': 'Doğum Tarihi', 'en': 'Birth Date'},
    'forgot_password': {'tr': 'Şifremi Unuttum', 'en': 'Forgot Password'},
    'reset_password': {'tr': 'Şifre Sıfırla', 'en': 'Reset Password'},
    'sign_in_with_google': {'tr': 'Google ile Giriş Yap', 'en': 'Sign in with Google'},
    'already_have_account': {'tr': 'Zaten hesabınız var mı?', 'en': 'Already have an account?'},
    'dont_have_account': {'tr': 'Hesabınız yok mu?', 'en': 'Don\'t have an account?'},
    'create_account': {'tr': 'Hesap Oluştur', 'en': 'Create Account'},
    
    // Home Screen
    'home': {'tr': 'Ana Sayfa', 'en': 'Home'},
    'learning': {'tr': 'Öğrenme', 'en': 'Learning'},
    'user': {'tr': 'Kullanıcı', 'en': 'User'},
    'user_data_not_found': {'tr': 'Kullanıcı verisi bulunamadı', 'en': 'User data not found'},
    'error_loading_user_data': {'tr': 'Kullanıcı verisi yüklenirken hata', 'en': 'Error loading user data'},
    'welcome_back': {'tr': 'Tekrar Hoş Geldiniz', 'en': 'Welcome Back'},
    'good_morning': {'tr': 'Günaydın', 'en': 'Good Morning'},
    'good_afternoon': {'tr': 'İyi Öğleden Sonralar', 'en': 'Good Afternoon'},
    'good_evening': {'tr': 'İyi Akşamlar', 'en': 'Good Evening'},
    'guest_user': {'tr': 'Misafir Kullanıcı', 'en': 'Guest User'},
    'daily_progress': {'tr': 'Günlük İlerleme', 'en': 'Daily Progress'},
    'study_time': {'tr': 'Çalışma Süresi', 'en': 'Study Time'},
    'completed_videos': {'tr': 'Tamamlanan Videolar', 'en': 'Completed Videos'},
    'browse_subjects': {'tr': 'Derslere Göz Atın', 'en': 'Browse Subjects'},
    
    // Subjects
    'mathematics': {'tr': 'Matematik', 'en': 'Mathematics'},
    'physics': {'tr': 'Fizik', 'en': 'Physics'},
    'chemistry': {'tr': 'Kimya', 'en': 'Chemistry'},
    'biology': {'tr': 'Biyoloji', 'en': 'Biology'},
    'turkish': {'tr': 'Türkçe', 'en': 'Turkish'},
    'history': {'tr': 'Tarih', 'en': 'History'},
    'geography': {'tr': 'Coğrafya', 'en': 'Geography'},
    'literature': {'tr': 'Edebiyat', 'en': 'Literature'},
    'english': {'tr': 'İngilizce', 'en': 'English'},
    'philosophy': {'tr': 'Felsefe', 'en': 'Philosophy'},
    
    // Subject Content Types
    'topic_videos': {'tr': 'VİDEO DERSLER', 'en': 'Video Lessons'},
    'sample_exams': {'tr': 'Örnek Yazılılar', 'en': 'Sample Exams'},
    'problem_solving': {'tr': 'Soru Çözümü', 'en': 'Problem Solving'},
    'practice_tests': {'tr': 'Deneme Sınavları', 'en': 'Practice Tests'},
    
    // Grade Levels
    'grade_9': {'tr': '9. Sınıf', 'en': '9th Grade'},
    'grade_10': {'tr': '10. Sınıf', 'en': '10th Grade'},
    'grade_11': {'tr': '11. Sınıf', 'en': '11th Grade'},
    'grade_12': {'tr': '12. Sınıf', 'en': '12th Grade'},
    'tyt': {'tr': 'TYT', 'en': 'TYT'},
    'ayt': {'tr': 'AYT', 'en': 'AYT'},
    'basic_topics': {'tr': 'Temel Konular', 'en': 'Basic Topics'},
    'intermediate_level': {'tr': 'Orta Seviye', 'en': 'Intermediate Level'},
    'advanced_topics': {'tr': 'İleri Konular', 'en': 'Advanced Topics'},
    'comprehensive': {'tr': 'Kapsamlı', 'en': 'Comprehensive'},
    'basic_qualification': {'tr': 'Temel Yeterlilik', 'en': 'Basic Qualification'},
    'field_qualification': {'tr': 'Alan Yeterlilik', 'en': 'Field Qualification'},
    'select_grade_level': {'tr': 'Sınıf Seviyesi Seçiniz', 'en': 'Select Grade Level'},
    
    // Statistics
    'statistics': {'tr': 'İstatistikler', 'en': 'Statistics'},
    'guest_restriction_title': {'tr': 'Gelişmiş İstatistikler', 'en': 'Advanced Statistics'},
    'guest_restriction_message': {'tr': 'İstatistikleri görüntülemek için hesap oluşturun', 'en': 'Create an account to view statistics'},
    'study_stats': {'tr': 'Çalışma İstatistikleri', 'en': 'Study Statistics'},
    'total_videos_watched': {'tr': 'İzlenen Video Sayısı', 'en': 'Total Videos Watched'},
    'total_study_time': {'tr': 'Toplam Çalışma Süresi', 'en': 'Total Study Time'},
    'average_session': {'tr': 'Ortalama Oturum', 'en': 'Average Session'},
    'this_week': {'tr': 'Bu Hafta', 'en': 'This Week'},
    'this_month': {'tr': 'Bu Ay', 'en': 'This Month'},
    'performance': {'tr': 'Performans', 'en': 'Performance'},
    'streak': {'tr': 'Çalışma Serisi', 'en': 'Study Streak'},
    'days': {'tr': 'gün', 'en': 'days'},
    'hours': {'tr': 'saat', 'en': 'hours'},
    'minutes': {'tr': 'dakika', 'en': 'minutes'},
    
    // Navigation Drawer
    'profile': {'tr': 'Profil', 'en': 'Profile'},
    'my_courses': {'tr': 'Derslerim', 'en': 'My Courses'},
    'achievements': {'tr': 'Başarılar', 'en': 'Achievements'},
    'settings': {'tr': 'Ayarlar', 'en': 'Settings'},
    'logout': {'tr': 'Çıkış Yap', 'en': 'Logout'},
    'guest_account': {'tr': 'Konuk hesabı', 'en': 'Guest account'},
    'guest_profile_restriction': {'tr': 'Sınırlı erişim - Hesap oluşturun', 'en': 'Limited access - Create account'},
    'guest_profile_message': {'tr': 'Profil özelliklerini kullanmak için hesap oluşturun', 'en': 'Create an account to use profile features'},
    
    // Settings Screen
    'appearance': {'tr': 'Görünüm', 'en': 'Appearance'},
    'dark_mode': {'tr': 'Karanlık Mod', 'en': 'Dark Mode'},
    'active': {'tr': 'Aktif', 'en': 'Active'},
    'inactive': {'tr': 'Pasif', 'en': 'Inactive'},
    'language': {'tr': 'Dil', 'en': 'Language'},
    'notifications': {'tr': 'Bildirimler', 'en': 'Notifications'},
    'email_notifications': {'tr': 'E-posta Bildirimleri', 'en': 'Email Notifications'},
    'push_notifications': {'tr': 'Anlık Bildirimler', 'en': 'Push Notifications'},
    'account': {'tr': 'Hesap', 'en': 'Account'},
    'profile_info': {'tr': 'Profil Bilgileri', 'en': 'Profile Information'},
    'edit_personal_info': {'tr': 'Kişisel bilgilerinizi düzenleyin', 'en': 'Edit your personal information'},
    'change_password': {'tr': 'Şifre Değiştir', 'en': 'Change Password'},
    'update_security': {'tr': 'Hesap güvenliğinizi güncelleyin', 'en': 'Update your account security'},
    'delete_account': {'tr': 'Hesabı Sil', 'en': 'Delete Account'},
    'delete_account_permanently': {'tr': 'Hesabınızı kalıcı olarak silin', 'en': 'Permanently delete your account'},
    'general': {'tr': 'Genel', 'en': 'General'},
    'sound_effects': {'tr': 'Ses Efektleri', 'en': 'Sound Effects'},
    'storage': {'tr': 'Depolama', 'en': 'Storage'},
    'cache_management': {'tr': 'Önbellek ve veri yönetimi', 'en': 'Cache and data management'},
    'about': {'tr': 'Hakkında', 'en': 'About'},
    'app_about': {'tr': 'Uygulama Hakkında', 'en': 'About App'},
    'version': {'tr': 'Sürüm 1.0.0', 'en': 'Version 1.0.0'},
    'help_support': {'tr': 'Yardım & Destek', 'en': 'Help & Support'},
    'faq_contact': {'tr': 'SSS ve iletişim', 'en': 'FAQ and contact'},
    'privacy_policy': {'tr': 'Gizlilik Politikası', 'en': 'Privacy Policy'},
    'data_protection': {'tr': 'Veri koruma ve kullanım şartları', 'en': 'Data protection and terms of use'},
    
    // Dialogs
    'select_language': {'tr': 'Dil Seçin', 'en': 'Select Language'},
    'delete_account_title': {'tr': 'Hesabı Sil', 'en': 'Delete Account'},
    'delete_account_confirm': {'tr': 'Bütün ilerlemen, görevlerin ve verilerin kalıcı olarak silinecek. Bu işlem geri alınamaz. Emin misin?', 'en': 'All your progress, quests and data will be permanently deleted. This action cannot be undone. Are you sure?'},
    'cancel': {'tr': 'İptal', 'en': 'Cancel'},
    'delete': {'tr': 'Sil', 'en': 'Delete'},
    'storage_management': {'tr': 'Depolama Yönetimi', 'en': 'Storage Management'},
    'cache_size': {'tr': 'Önbellek Boyutu', 'en': 'Cache Size'},
    'downloaded_content': {'tr': 'İndirilen İçerik', 'en': 'Downloaded Content'},
    'close': {'tr': 'Kapat', 'en': 'Close'},
    'clear_cache': {'tr': 'Önbelleği Temizle', 'en': 'Clear Cache'},
    'cache_cleared': {'tr': 'Önbellek temizlendi', 'en': 'Cache cleared'},
         'contact_info': {'tr': 'İletişim Bilgileri', 'en': 'Contact Information'},
     'contact_message': {'tr': 'Yardım için bizimle iletişime geçin:', 'en': 'Contact us for help:'},
     'save': {'tr': 'Kaydet', 'en': 'Save'},
    
    // Video Player
    'play': {'tr': 'Oynat', 'en': 'Play'},
    'pause': {'tr': 'Duraklat', 'en': 'Pause'},
    'fullscreen': {'tr': 'Tam Ekran', 'en': 'Fullscreen'},
    'quality': {'tr': 'Kalite', 'en': 'Quality'},
    'speed': {'tr': 'Hız', 'en': 'Speed'},
    'subtitles': {'tr': 'Altyazı', 'en': 'Subtitles'},
    'completed': {'tr': 'Tamamlandı', 'en': 'Completed'},
    'progress': {'tr': 'İlerleme', 'en': 'Progress'},
    'video_information': {'tr': 'Video Bilgileri', 'en': 'Video Information'},
    'video_description': {'tr': 'Bu video, konuları daha iyi anlamanıza yardımcı olacak eğitici içerik barındırır.', 'en': 'This video contains educational content to help you better understand the topics.'},
    
    // Content Description
    'video_count': {'tr': 'video', 'en': 'videos'},
    'duration': {'tr': 'Süre', 'en': 'Duration'},
    'difficulty': {'tr': 'Zorluk', 'en': 'Difficulty'},
    'beginner': {'tr': 'Başlangıç', 'en': 'Beginner'},
    'intermediate': {'tr': 'Orta', 'en': 'Intermediate'},
    'advanced': {'tr': 'İleri', 'en': 'Advanced'},
    'expert': {'tr': 'Uzman', 'en': 'Expert'},
    
    // Error Messages
    'network_error': {'tr': 'İnternet bağlantı hatası', 'en': 'Network connection error'},
    'login_failed': {'tr': 'Giriş başarısız', 'en': 'Login failed'},
    'google_login_failed': {'tr': 'Google ile giriş başarısız', 'en': 'Google sign in failed'},
    'registration_failed': {'tr': 'Kayıt başarısız', 'en': 'Registration failed'},
    'invalid_email': {'tr': 'Geçersiz e-posta adresi', 'en': 'Invalid email address'},
    'weak_password': {'tr': 'Şifre çok zayıf', 'en': 'Password too weak'},
    'passwords_dont_match': {'tr': 'Şifreler eşleşmiyor', 'en': 'Passwords don\'t match'},
    'field_required': {'tr': 'Bu alan zorunludur', 'en': 'This field is required'},
    
    // Success Messages
    'login_successful': {'tr': 'Giriş başarılı', 'en': 'Login successful'},
    'registration_successful': {'tr': 'Kayıt başarılı', 'en': 'Registration successful'},
    'password_changed': {'tr': 'Şifre değiştirildi', 'en': 'Password changed'},
    'profile_updated': {'tr': 'Profil güncellendi', 'en': 'Profile updated'},
    'logout_successful': {'tr': 'Çıkış yapıldı', 'en': 'Logged out successfully'},
    
    // Additional UI Elements
    'edit': {'tr': 'Düzenle', 'en': 'Edit'},
    'remove_from_favorites': {'tr': 'Favorilerden Çıkar', 'en': 'Remove from Favorites'},
    'restore': {'tr': 'Geri Yükle', 'en': 'Restore'},
    'delete_permanently': {'tr': 'Kalıcı Sil', 'en': 'Delete Permanently'},
    'page_not_found': {'tr': 'Sayfa bulunamadı', 'en': 'Page not found'},
    'video_player': {'tr': 'Video Oynatıcı', 'en': 'Video Player'},
    'recycle_bin': {'tr': 'Geri Dönüşüm Kutusu', 'en': 'Recycle Bin'},
    'delete_all': {'tr': 'Tümünü Sil', 'en': 'Delete All'},
    
    // Password Reset
    'forgot_password_title': {'tr': 'Şifre Sıfırlama', 'en': 'Password Reset'},
    'password_reset_email_sent': {'tr': 'Şifre sıfırlama e-postası gönderildi.', 'en': 'Password reset email sent.'},
    'password_reset_email_sent_to': {'tr': 'Şifre sıfırlama e-postası adresine gönderildi.', 'en': 'Password reset email sent to address.'},
    'try_different_email': {'tr': 'Farklı E-posta ile Dene', 'en': 'Try Different Email'},
    'back_to_login': {'tr': 'Giriş Sayfasına Geri Dön', 'en': 'Back to Login'},
    'set_new_password': {'tr': 'Yeni Şifre Belirle', 'en': 'Set New Password'},
    'password_reset_success': {'tr': 'Şifreniz başarıyla sıfırlandı!', 'en': 'Your password has been reset successfully!'},
    'password_update_success': {'tr': 'Şifre başarıyla güncellendi', 'en': 'Password updated successfully'},
    
    // Email Verification
    'email_verified_success': {'tr': 'Email başarıyla doğrulandı!', 'en': 'Email verified successfully!'},
    'email_recovered_success': {'tr': 'Email başarıyla geri yüklendi!', 'en': 'Email recovered successfully!'},
    
    // Task Management
    'task_title': {'tr': 'Başlık', 'en': 'Title'},
    'task_description': {'tr': 'Açıklama', 'en': 'Description'},
    
    // Content Screens
    'topic_explanation_videos': {'tr': 'VİDEO DERSLER', 'en': 'Video Lessons'},
    'sample_exams_screen': {'tr': 'Örnek Yazılılar', 'en': 'Sample Exams'},
    'problem_solving_videos': {'tr': 'Soru Çözüm Videoları', 'en': 'Problem Solving Videos'},
    
    // QR Scanner
    'scan_error': {'tr': 'Tarama Hatası', 'en': 'Scan Error'},
    
    // Generic Messages
    'pdf_open_error': {'tr': 'PDF açılamadı', 'en': 'Could not open PDF'},
    'unexpected_error': {'tr': 'Beklenmeyen bir hata oluştu', 'en': 'An unexpected error occurred'},
    'registration_error': {'tr': 'Kayıt sırasında hata oluştu', 'en': 'Error occurred during registration'},
    'cannot_find_manual_entry': {'tr': 'Bulamıyorum, manuel gireceğim', 'en': 'Can\'t find it, I\'ll enter manually'},
    'select_from_list': {'tr': 'Listeden seç', 'en': 'Select from list'},
    'complete_registration': {'tr': 'Kaydı Tamamla', 'en': 'Complete Registration'},
    'go_back': {'tr': 'Geri Dön', 'en': 'Go Back'},
    'return_to_home': {'tr': 'Ana Sayfaya Dön', 'en': 'Return to Home'},
    'edit_profile_coming_soon': {'tr': 'Profil düzenleme yakında eklenecek', 'en': 'Profile editing coming soon'},
    'edit_profile_button': {'tr': 'Profili Düzenle', 'en': 'Edit Profile'},
    'save_info_failed': {'tr': 'Bilgileri kaydetme başarısız', 'en': 'Failed to save information'},
    'privacy_policy_coming_soon': {'tr': 'Gizlilik politikası yakında eklenecek', 'en': 'Privacy policy coming soon'},
    'account_deletion_coming_soon': {'tr': 'Hesap silme özelliği yakında eklenecek', 'en': 'Account deletion feature coming soon'},
    'teacher_panel_coming_soon': {'tr': 'Öğretmen paneli yakında gelecek!', 'en': 'Teacher panel coming soon!'},
    'account_deleted': {'tr': 'Hesap başarıyla silindi', 'en': 'Account deleted successfully'},
    'reauth_required': {'tr': 'Güvenlik gereği tekrar giriş yapıp deneyin', 'en': 'Please sign in again for security reasons'},
  };
} 