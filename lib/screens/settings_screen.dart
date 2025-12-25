import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../blocs/bloc_exports.dart';
import '../utils/app_icons.dart';
import '../services/localization_service.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'change_password_screen.dart';
import 'login_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';
import '../widgets/neumorphic/neumorphic_text_field.dart';

class SettingsScreen extends StatefulWidget {
  static const String id = 'settings_screen';
  final bool isGuest;

  const SettingsScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String _selectedLanguage = 'Türkçe';
  bool _notificationsEnabled = true;
  bool _emailNotifications = false;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  
  // Profile data
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _classController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  Map<String, dynamic>? _profileData;

  final List<Map<String, String>> _languages = [
    {'code': 'tr', 'name': 'Türkçe'},
    {'code': 'en', 'name': 'English'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _classController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await LocalizationService.initialize();
    await _loadSettings();
    if (!widget.isGuest) {
      await _loadProfileData();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('language') ?? 'Türkçe';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? false;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', _selectedLanguage);
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setBool('email_notifications', _emailNotifications);
    await prefs.setBool('push_notifications', _pushNotifications);
    await prefs.setBool('sound_enabled', _soundEnabled);
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        _profileData = doc.data();
        setState(() {
          _fullNameController.text = _profileData?['fullName'] ?? '';
          _emailController.text = _profileData?['email'] ?? '';
          _classController.text = _profileData?['class'] ?? '';
          _institutionController.text = _profileData?['institution']?['name'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': _fullNameController.text.trim(),
        'class': _classController.text.trim(),
        'institution': {
          'name': _institutionController.text.trim(),
          'type': 'manual',
          'isManual': true,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<LanguageBloc>().translate('profile_updated')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        final bgColor = NeumorphicColors.getBackground(context);
        final textColor = NeumorphicColors.getText(context);

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: Column(
              children: [
                // Neumorphic Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      NeumorphicButton(
                        onPressed: () => Navigator.pop(context),
                        padding: const EdgeInsets.all(12),
                        borderRadius: 12,
                        child: Icon(AppIcons.arrowBack, color: textColor),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        languageBloc.translate('settings'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: ListView(
                        padding: const EdgeInsets.all(24.0),
                        children: [
                          // Appearance Section
                          _buildSectionTitle(languageBloc.translate('appearance'), AppIcons.settings),
                          const SizedBox(height: 16),
                          _buildThemeToggle(languageBloc),
                          const SizedBox(height: 16),
                          _buildLanguageSelector(languageBloc),
                          
                          const SizedBox(height: 32),
                          
                          // Notifications Section
                          _buildSectionTitle(languageBloc.translate('notifications'), AppIcons.notification),
                          const SizedBox(height: 16),
                          _buildNotificationSettings(languageBloc),
                          
                          const SizedBox(height: 32),
                          
                          // Account Section (only for registered users)
                          if (!widget.isGuest) ...[
                            _buildSectionTitle(languageBloc.translate('account'), AppIcons.person),
                            const SizedBox(height: 16),
                            _buildAccountSettings(languageBloc),
                            const SizedBox(height: 32),
                          ],
                          
                          // General Section
                          _buildSectionTitle(languageBloc.translate('general'), AppIcons.settings),
                          const SizedBox(height: 16),
                          _buildGeneralSettings(languageBloc),
                          
                          const SizedBox(height: 32),
                          
                          // About Section
                          _buildSectionTitle(languageBloc.translate('about'), AppIcons.info),
                          const SizedBox(height: 16),
                          _buildAboutSection(languageBloc),
                      
                          const SizedBox(height: 100), // Bottom padding
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: NeumorphicColors.accentBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: NeumorphicColors.accentBlue,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(LanguageBloc languageBloc) {
    return BlocBuilder<SwitchBloc, SwitchState>(
      builder: (context, state) {
        return _buildNeumorphicSettingCard(
          icon: state.switchValue ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          title: languageBloc.translate('dark_mode'),
          subtitle: state.switchValue 
              ? languageBloc.translate('active') 
              : languageBloc.translate('inactive'),
          trailing: Switch(
            value: state.switchValue,
            onChanged: (value) {
              if (value) {
                context.read<SwitchBloc>().add(SwitchOnEvent());
              } else {
                context.read<SwitchBloc>().add(SwitchOffEvent());
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLanguageSelector(LanguageBloc languageBloc) {
    return _buildNeumorphicSettingCard(
      icon: Icons.language_rounded,
      title: languageBloc.translate('language'),
      subtitle: _selectedLanguage,
      trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
      onTap: () => _showLanguageDialog(),
    );
  }

  Widget _buildNotificationSettings(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildNeumorphicSettingCard(
          icon: AppIcons.notification,
          title: languageBloc.translate('notifications'),
          subtitle: _notificationsEnabled 
              ? languageBloc.translate('active') 
              : languageBloc.translate('inactive'),
          trailing: Switch(
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              if (value) {
                NotificationService.instance.requestPermission();
              }
              NotificationService.instance.enableNotifications(value);
              _saveSettings();
            },
          ),
        ),
        if (_notificationsEnabled) ...[
          const SizedBox(height: 16),
          _buildNeumorphicSettingCard(
            icon: AppIcons.email,
            title: languageBloc.translate('email_notifications'),
            subtitle: _emailNotifications 
                ? languageBloc.translate('active') 
                : languageBloc.translate('inactive'),
            trailing: Switch(
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
                NotificationService.instance.setEmailNotifications(value);
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildNeumorphicSettingCard(
            icon: AppIcons.notification,
            title: languageBloc.translate('push_notifications'),
            subtitle: _pushNotifications 
                ? languageBloc.translate('active') 
                : languageBloc.translate('inactive'),
            trailing: Switch(
              value: _pushNotifications,
              onChanged: (value) {
                setState(() {
                  _pushNotifications = value;
                });
                NotificationService.instance.setPushNotifications(value);
                _saveSettings();
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAccountSettings(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildNeumorphicSettingCard(
          icon: AppIcons.person,
          title: languageBloc.translate('profile_info'),
          subtitle: languageBloc.translate('edit_personal_info'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () => _showProfileEditDialog(),
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: AppIcons.lock,
          title: languageBloc.translate('change_password'),
          subtitle: languageBloc.translate('update_security'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () {
            Navigator.pushNamed(context, ChangePasswordScreen.id);
          },
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: Icons.logout_rounded,
          title: languageBloc.translate('logout'),
          subtitle: languageBloc.translate('end_session'),
          trailing: Icon(AppIcons.arrowForward, color: Colors.red.withValues(alpha: 0.5)),
          onTap: _logout,
          isDestructive: true,
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: AppIcons.delete,
          title: languageBloc.translate('delete_account'),
          subtitle: languageBloc.translate('delete_account_permanently'),
          trailing: Icon(AppIcons.arrowForward, color: Colors.red.withValues(alpha: 0.5)),
          onTap: () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildNeumorphicSettingCard(
          icon: _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          title: languageBloc.translate('sound_effects'),
          subtitle: _soundEnabled 
              ? languageBloc.translate('active') 
              : languageBloc.translate('inactive'),
          trailing: Switch(
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });
              _saveSettings();
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: Icons.storage_rounded,
          title: languageBloc.translate('storage'),
          subtitle: languageBloc.translate('cache_management'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () => _showStorageDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildNeumorphicSettingCard(
          icon: AppIcons.info,
          title: languageBloc.translate('app_about'),
          subtitle: languageBloc.translate('version'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () => _showAboutDialog(),
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: Icons.help_rounded,
          title: languageBloc.translate('help_support'),
          subtitle: languageBloc.translate('faq_contact'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () => _showContactDialog(),
        ),
        const SizedBox(height: 16),
        _buildNeumorphicSettingCard(
          icon: Icons.shield_rounded,
          title: languageBloc.translate('privacy_policy'),
          subtitle: languageBloc.translate('data_protection'),
          trailing: Icon(AppIcons.arrowForward, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gizlilik politikası yakında eklenecek'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNeumorphicSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final textColor = NeumorphicColors.getText(context);
    final iconColor = isDestructive ? Colors.red : NeumorphicColors.accentBlue;
    final titleColor = isDestructive ? Colors.red : textColor;

    return NeumorphicButton(
      onPressed: onTap,
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Row(
        children: [
          NeumorphicContainer(
            padding: const EdgeInsets.all(10),
            borderRadius: 12,
            depth: 2,
            color: isDestructive ? Colors.red.withValues(alpha: 0.1) : null,
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    // Keeping existing dialog logic for now, but should ideally use neumorphic dialog
    showDialog(
      context: context,
      builder: (context) {
        return BlocBuilder<LanguageBloc, LanguageState>(
          builder: (context, languageState) {
            return AlertDialog(
              title: Text(context.read<LanguageBloc>().translate('select_language')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: _languages.map((language) {
                  return RadioListTile<String>(
                    title: Text(language['name']!),
                    value: language['name']!,
                    groupValue: _selectedLanguage,
                    onChanged: (value) async {
                      setState(() {
                        _selectedLanguage = value!;
                      });
                      
                      String languageCode = _languages
                          .firstWhere((lang) => lang['name'] == value)['code']!;
                      context.read<LanguageBloc>().add(LanguageChanged(languageCode));
                      await _saveSettings();
                      
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final textColor = NeumorphicColors.getText(context);
        return Dialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocalizationService.translate('profile_info'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),
                NeumorphicTextField(
                  controller: _fullNameController,
                  hintText: LocalizationService.translate('full_name'),
                  prefixIcon: Icon(AppIcons.person, color: textColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                NeumorphicTextField(
                  controller: _emailController,
                  hintText: LocalizationService.translate('email'),
                  prefixIcon: Icon(AppIcons.email, color: textColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                NeumorphicTextField(
                  controller: _classController,
                  hintText: LocalizationService.translate('class'),
                  prefixIcon: Icon(AppIcons.school, color: textColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 16),
                NeumorphicTextField(
                  controller: _institutionController,
                  hintText: LocalizationService.translate('institution'),
                  prefixIcon: Icon(Icons.school_rounded, color: textColor.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(LocalizationService.translate('cancel')),
                    ),
                    const SizedBox(width: 16),
                    NeumorphicButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveProfileData();
                      },
                      color: NeumorphicColors.accentBlue,
                      child: Text(
                        LocalizationService.translate('save'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('delete_account_title')),
          content: Text(LocalizationService.translate('delete_account_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                LocalizationService.translate('delete'), 
                style: const TextStyle(color: Colors.white)
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      await UserService.clearAllUserData();
      if (mounted) {
        context.read<UserProfileBloc>().add(const ClearUserProfile());
        Navigator.pushNamedAndRemoveUntil(context, LoginScreen.id, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Çıkış yapılamadı: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      await AuthService().deleteUserAccount();
      
      if (mounted) {
        context.read<UserProfileBloc>().add(const ClearUserProfile());
        Navigator.pushNamedAndRemoveUntil(context, LoginScreen.id, (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocalizationService.translate('account_deleted')),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hesap silme hatası: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final textColor = NeumorphicColors.getText(context);
        return Dialog(
          backgroundColor: NeumorphicColors.getBackground(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.support_agent_rounded, size: 48, color: NeumorphicColors.accentBlue),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('contact_info'),
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('contact_message'),
                  style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 12,
                  child: Row(
                    children: [
                      Icon(AppIcons.email, color: NeumorphicColors.accentBlue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'renasamedia@gmail.com',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                NeumorphicButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(LocalizationService.translate('close')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStorageDialog() {
    // Simplified dialog for brevity
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocalizationService.translate('storage_management')),
        content: const Text('Cache info here...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocalizationService.translate('close')),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Performax',
      applicationVersion: '1.0.0',
    );
  }
}
