import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class ProfileOverlay extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ProfileOverlay({
    super.key,
    this.userData,
  });

  @override
  State<ProfileOverlay> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> 
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    ));
    
    _backgroundController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  void _close() async {
    await _slideController.reverse();
    await _backgroundController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  String _getDisplayName() {
    return widget.userData?['fullName'] ?? 
           '${widget.userData?['firstName'] ?? 'Kullanıcı'} ${widget.userData?['lastName'] ?? ''}'.trim();
  }

  String _getInitials() {
    final fullName = widget.userData?['fullName'];
    if (fullName != null && fullName.isNotEmpty) {
      final nameParts = fullName.split(' ');
      if (nameParts.length >= 2) {
        return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
      } else {
        return fullName[0].toUpperCase();
      }
    }
    
    final firstName = widget.userData?['firstName'];
    if (firstName != null && firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    }
    
    return 'U';
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  DateTime? _getBirthDate() {
    if (widget.userData?['birthDate'] == null) return null;
    
    final birthDateData = widget.userData!['birthDate'];
    if (birthDateData is Timestamp) {
      return birthDateData.toDate();
    }
    
    return null;
  }

  String _getInstitutionName() {
    // First, try to get school from direct 'school' field (from UserProfile.toMap())
    final school = widget.userData?['school'];
    if (school != null && school is String && school.isNotEmpty) {
      return school;
    }
    
    // Fallback: try to get from 'institution' field (from raw Firestore data)
    final institution = widget.userData?['institution'];
    if (institution == null) {
      return 'Belirtilmemiş';
    }
    
    if (institution is Map<String, dynamic>) {
      return institution['name'] ?? 'Bilinmiyor';
    }
    
    return institution.toString();
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background overlay
          AnimatedBuilder(
            animation: _backgroundAnimation,
            builder: (context, child) {
              return GestureDetector(
                onTap: _close,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5 * _backgroundAnimation.value),
                ),
              );
            },
          ),
          
          // Profile panel
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) {
              return SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: screenHeight * 0.75,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withValues(alpha: 0.9),
                          theme.primaryColor,
                          theme.colorScheme.secondary,
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Column(
                          children: [
                            // Handle bar
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            
                            // Header
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Profile Avatar
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(25),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 20,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(25),
                                      child: Image.asset(
                                        'assets/avatars/2d/test_model_profil.png',
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback to initials if image fails to load
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(25),
                                              gradient: LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Colors.white.withValues(alpha: 0.3),
                                                  Colors.white.withValues(alpha: 0.1),
                                                ],
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _getInitials(),
                                                style: const TextStyle(
                                                  fontSize: 40,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  Text(
                                    _getDisplayName(),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Performax Öğrencisi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Content
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      // Email
                                      _buildInfoTile(
                                        icon: Icons.email_outlined,
                                        label: 'E-posta',
                                        value: widget.userData?['email'] ?? 'Belirtilmemiş',
                                        color: const Color(0xFF06B6D4),
                                      ),
                                      
                                      // Class
                                      if (widget.userData?['class'] != null) ...[
                                        _buildInfoTile(
                                          icon: Icons.school_outlined,
                                          label: 'Sınıf',
                                          value: widget.userData!['class'],
                                          color: const Color(0xFF10B981),
                                        ),
                                      ],
                                      
                                      // Age
                                      if (_getBirthDate() != null) ...[
                                        _buildInfoTile(
                                          icon: Icons.cake_outlined,
                                          label: 'Yaş',
                                          value: '${_calculateAge(_getBirthDate())} yaşında',
                                          subtitle: 'Doğum tarihi: ${_getBirthDate()!.day.toString().padLeft(2, '0')}/${_getBirthDate()!.month.toString().padLeft(2, '0')}/${_getBirthDate()!.year}',
                                          color: Colors.orange,
                                        ),
                                      ],
                                      
                                      // Institution
                                      _buildInfoTile(
                                        icon: Icons.location_city_outlined,
                                        label: 'Okul/Dershane',
                                        value: _getInstitutionName(),
                                        color: Colors.purple,
                                      ),
                                      
                                      // Registration Date
                                      if (widget.userData?['registrationDate'] != null) ...[
                                        _buildInfoTile(
                                          icon: Icons.calendar_today_outlined,
                                          label: 'Kayıt Tarihi',
                                          value: (() {
                                            final date = (widget.userData!['registrationDate'] as Timestamp).toDate();
                                            return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                          })(),
                                          color: const Color(0xFF6366F1),
                                        ),
                                      ],
                                      
                                      const SizedBox(height: 100), // Bottom padding
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
} 