import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../blocs/bloc_exports.dart';
import '../utils/app_icons.dart';
import '../services/localization_service.dart';
import 'change_password_screen.dart';

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
    final theme = Theme.of(context);
    
    return BlocBuilder<LanguageBloc, LanguageState>(
      builder: (context, languageState) {
        final languageBloc = context.read<LanguageBloc>();
        
        return Scaffold(
          appBar: AppBar(
            title: Text(
              languageBloc.translate('settings'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(AppIcons.arrowBack),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Appearance Section
                    _buildSectionTitle(languageBloc.translate('appearance'), AppIcons.settings),
                    const SizedBox(height: 8),
                    _buildThemeToggle(languageBloc),
                    const SizedBox(height: 16),
                    _buildLanguageSelector(languageBloc),
                    
                    const SizedBox(height: 32),
                    
                    // Notifications Section
                    _buildSectionTitle(languageBloc.translate('notifications'), AppIcons.notification),
                    const SizedBox(height: 8),
                    _buildNotificationSettings(languageBloc),
                    
                    const SizedBox(height: 32),
                    
                    // Account Section (only for registered users)
                    if (!widget.isGuest) ...[
                      _buildSectionTitle(languageBloc.translate('account'), AppIcons.person),
                      const SizedBox(height: 8),
                      _buildAccountSettings(languageBloc),
                      const SizedBox(height: 32),
                    ],
                    
                    // General Section
                    _buildSectionTitle(languageBloc.translate('general'), AppIcons.settings),
                    const SizedBox(height: 8),
                    _buildGeneralSettings(languageBloc),
                    
                    const SizedBox(height: 32),
                    
                                        // About Section
                    _buildSectionTitle(languageBloc.translate('about'), AppIcons.info),
                    const SizedBox(height: 8),
                    _buildAboutSection(languageBloc),
                
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        AppIcons.holographicIcon(
          icon,
          size: 20,
          primaryColor: Theme.of(context).primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeToggle(LanguageBloc languageBloc) {
    return BlocBuilder<SwitchBloc, SwitchState>(
      builder: (context, state) {
        return _buildSettingCard(
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
    return _buildSettingCard(
      icon: Icons.language_rounded,
      title: languageBloc.translate('language'),
      subtitle: _selectedLanguage,
      trailing: const Icon(AppIcons.arrowForward),
      onTap: () => _showLanguageDialog(),
    );
  }

  Widget _buildNotificationSettings(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildSettingCard(
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
              _saveSettings();
            },
          ),
        ),
        if (_notificationsEnabled) ...[
          const SizedBox(height: 8),
          _buildSettingCard(
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
                _saveSettings();
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingCard(
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
        _buildSettingCard(
          icon: AppIcons.person,
          title: languageBloc.translate('profile_info'),
          subtitle: languageBloc.translate('edit_personal_info'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () => _showProfileEditDialog(),
        ),
        const SizedBox(height: 8),
        _buildSettingCard(
          icon: AppIcons.lock,
          title: languageBloc.translate('change_password'),
          subtitle: languageBloc.translate('update_security'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () {
            Navigator.pushNamed(context, ChangePasswordScreen.id);
          },
        ),
        const SizedBox(height: 8),
        _buildSettingCard(
          icon: AppIcons.delete,
          title: languageBloc.translate('delete_account'),
          subtitle: languageBloc.translate('delete_account_permanently'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () => _showDeleteAccountDialog(),
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildGeneralSettings(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildSettingCard(
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
        const SizedBox(height: 8),
        _buildSettingCard(
          icon: Icons.storage_rounded,
          title: languageBloc.translate('storage'),
          subtitle: languageBloc.translate('cache_management'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () => _showStorageDialog(),
        ),
      ],
    );
  }

  Widget _buildAboutSection(LanguageBloc languageBloc) {
    return Column(
      children: [
        _buildSettingCard(
          icon: AppIcons.info,
          title: languageBloc.translate('app_about'),
          subtitle: languageBloc.translate('version'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () => _showAboutDialog(),
        ),
        const SizedBox(height: 8),
        _buildSettingCard(
          icon: Icons.help_rounded,
          title: languageBloc.translate('help_support'),
          subtitle: languageBloc.translate('faq_contact'),
          trailing: const Icon(AppIcons.arrowForward),
          onTap: () => _showContactDialog(),
        ),
        const SizedBox(height: 8),
        _buildSettingCard(
          icon: Icons.shield_rounded,
          title: languageBloc.translate('privacy_policy'),
          subtitle: languageBloc.translate('data_protection'),
          trailing: const Icon(AppIcons.arrowForward),
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

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final cardColor = isDestructive 
        ? Colors.red.withValues(alpha: 0.1) 
        : theme.cardTheme.color;
    final iconColor = isDestructive 
        ? Colors.red 
        : theme.primaryColor;
    final titleColor = isDestructive 
        ? Colors.red 
        : theme.textTheme.titleMedium?.color;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AppIcons.holographicIcon(
                  icon,
                  size: 24,
                  primaryColor: iconColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
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
                      
                      // Update the language using LanguageBloc
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocalizationService.translate('profile_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate('full_name'),
                    prefixIcon: const Icon(AppIcons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate('email'),
                    prefixIcon: const Icon(AppIcons.email),
                  ),
                  enabled: false, // Email cannot be changed
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate('class'),
                    prefixIcon: const Icon(AppIcons.school),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _institutionController,
                  decoration: InputDecoration(
                    labelText: LocalizationService.translate('institution'),
                    prefixIcon: const Icon(Icons.school_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Reset to original values
                        _loadProfileData();
                      },
                      child: Text(LocalizationService.translate('cancel')),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveProfileData();
                      },
                      child: Text(LocalizationService.translate('save')),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Hesap silme özelliği yakında eklenecek'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcons.holographicIcon(
                  Icons.support_agent_rounded,
                  size: 48,
                  primaryColor: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('contact_info'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  LocalizationService.translate('contact_message'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.email,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'renasamedia@gmail.com',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
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
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(LocalizationService.translate('storage_management')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.storage_rounded),
                title: Text(LocalizationService.translate('cache_size')),
                subtitle: const Text('~45 MB'),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded),
                title: Text(LocalizationService.translate('downloaded_content')),
                subtitle: const Text('~120 MB'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(LocalizationService.translate('close')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(LocalizationService.translate('cache_cleared')),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(LocalizationService.translate('clear_cache')),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Performax',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: const Icon(
          AppIcons.school,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Performax, modern eğitim teknolojileri ile öğrenme deneyiminizi geliştiren kapsamlı bir eğitim platformudur.',
        ),
        const SizedBox(height: 16),
        const Text(
          '© 2024 Performax. Tüm hakları saklıdır.',
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
} 