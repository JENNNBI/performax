import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar_circle.dart';

class ProfileScreen extends StatefulWidget {
  static const String id = '/profile';
  
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    
    _loadUserData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'Kullanıcı oturumu bulunamadı';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userData = doc.data();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Kullanıcı verileri bulunamadı';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Veri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  DateTime? _getBirthDate() {
    if (_userData?['birthDate'] == null) return null;
    
    final birthDateData = _userData!['birthDate'];
    if (birthDateData is Timestamp) {
      return birthDateData.toDate();
    }
    
    return null;
  }

  String _getInstitutionName() {
    final institution = _userData?['institution'];
    if (institution == null) return 'Belirtilmemiş';
    
    if (institution is Map<String, dynamic>) {
      // Check if it's manual entry
      if (institution['isManual'] == true) {
        return institution['name'] ?? 'Manuel Giriş';
      }
      
      // Check if it's from institution object
      return institution['name'] ?? 'Bilinmiyor';
    }
    
    return institution.toString();
  }

  String _getInstitutionDetails() {
    final institution = _userData?['institution'];
    if (institution == null) return '';
    
    if (institution is Map<String, dynamic>) {
      if (institution['isManual'] == true) {
        return 'Manuel olarak girildi';
      }
      
      final city = institution['city'];
      final district = institution['district'];
      final type = institution['type'];
      
      List<String> details = [];
      if (city != null) details.add(city);
      if (district != null) details.add(district);
      if (type != null) {
        if (type == 'lise') {
          details.add('Lise');
        } else if (type == 'dershane') {
          details.add('Dershane');
        }
      }
      
      return details.isNotEmpty ? details.join(', ') : '';
    }
    
    return '';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    String? subtitle,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? Theme.of(context).primaryColor).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: iconColor ?? Theme.of(context).primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withValues(alpha: 0.8),
              theme.primaryColor,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushReplacementNamed('/home');
                            },
                            child: const Text('Ana Sayfaya Dön'),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Header
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    const UserAvatarCircle(
                                      radius: 40,
                                      showBorder: true,
                                      borderColor: Colors.white,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Profilim',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Kayıt bilgileriniz başarıyla kaydedildi',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Profile Information Cards
                              _buildInfoCard(
                                icon: Icons.email_outlined,
                                title: 'E-posta Adresi',
                                value: _userData?['email'] ?? 'Belirtilmemiş',
                                iconColor: Colors.blue,
                              ),
                              
                              if (_userData?['fullName'] != null) ...[
                                _buildInfoCard(
                                  icon: Icons.person_outline,
                                  title: 'Ad Soyad',
                                  value: _userData!['fullName'],
                                  iconColor: Colors.indigo,
                                ),
                              ],
                              
                              if (_userData?['class'] != null) ...[
                                _buildInfoCard(
                                  icon: Icons.school_outlined,
                                  title: 'Sınıf',
                                  value: _userData!['class'],
                                  iconColor: Colors.teal,
                                ),
                              ],
                              
                              if (_getBirthDate() != null) ...[
                                _buildInfoCard(
                                  icon: Icons.cake_outlined,
                                  title: 'Yaş',
                                  value: '${_calculateAge(_getBirthDate())} yaşında',
                                  subtitle: 'Doğum tarihi: ${_getBirthDate()!.day.toString().padLeft(2, '0')}/${_getBirthDate()!.month.toString().padLeft(2, '0')}/${_getBirthDate()!.year}',
                                  iconColor: Colors.orange,
                                ),
                              ],
                              
                              _buildInfoCard(
                                icon: Icons.school_outlined,
                                title: 'Okul/Dershane',
                                value: _getInstitutionName(),
                                subtitle: _getInstitutionDetails(),
                                iconColor: Colors.green,
                              ),
                              
                              _buildInfoCard(
                                icon: Icons.calendar_today_outlined,
                                title: 'Kayıt Tarihi',
                                value: _userData?['registrationDate'] != null
                                    ? (() {
                                        final date = (_userData!['registrationDate'] as Timestamp).toDate();
                                        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                      })()
                                    : 'Bilinmiyor',
                                iconColor: Colors.purple,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Action Buttons
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.of(context).pushReplacementNamed('/home');
                                      },
                                      icon: const Icon(Icons.home),
                                      label: const Text('Ana Sayfaya Git'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: theme.primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final isGuest = await UserService.isGuestUser();
                                        if (context.mounted) {
                                          Navigator.pushNamed(
                                            context,
                                            SettingsScreen.id,
                                            arguments: isGuest,
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Profili Düzenle'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(color: Colors.white, width: 2),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
} 