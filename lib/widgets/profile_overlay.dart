import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/user_avatar_circle.dart';

class ProfileOverlay extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const ProfileOverlay({
    super.key,
    this.userData,
  });

  @override
  State<ProfileOverlay> createState() => _ProfileOverlayState();
}

class _ProfileOverlayState extends State<ProfileOverlay> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _backgroundAnimation = CurvedAnimation(
      parent: _backgroundController,
      curve: Curves.easeOut,
    );

    _slideController.forward();
    _backgroundController.forward();
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

  String _getInstitutionName() {
    if (widget.userData?['institutionName'] != null) {
      return widget.userData!['institutionName'];
    }
    
    if (widget.userData?['institution'] != null) {
      if (widget.userData!['institution'] is Map) {
        return widget.userData!['institution']['name'] ?? 'Belirtilmemiş';
      } else if (widget.userData!['institution'] is String) {
        return widget.userData!['institution'];
      }
    }
    
    return '(AHATLI MAH) KEPEZ GIYASEDDİN KEYHÜSREV ANADOLU İMAM HATİP LİSESİ';
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
        color: const Color(0xFF1E293B), // Dark Card Background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
              color: color.withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.5), // Light Grey Label
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white, // White Value
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
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
                  color: Colors.black.withValues(alpha: 0.7 * _backgroundAnimation.value),
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
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F172A), // Deep Blue Background
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: Column(
                        children: [
                          // Handle bar
                          Container(
                            margin: const EdgeInsets.only(top: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
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
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withValues(alpha: 0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const UserAvatarCircle(
                                    radius: 50,
                                    showBorder: true,
                                    borderColor: Colors.cyanAccent,
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
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                                  ),
                                  child: const Text(
                                    'Performax Öğrencisi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.cyanAccent,
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
                                      icon: Icons.email_rounded,
                                      label: 'E-posta',
                                      value: widget.userData?['email'] ?? 'Belirtilmemiş',
                                      color: const Color(0xFF06B6D4), // Cyan
                                    ),
                                    
                                    // Class
                                    if (widget.userData?['class'] != null) ...[
                                      _buildInfoTile(
                                        icon: Icons.school_rounded,
                                        label: 'Sınıf',
                                        value: widget.userData!['class'],
                                        color: const Color(0xFF10B981), // Emerald
                                      ),
                                    ],
                                    
                                    // Institution
                                    _buildInfoTile(
                                      icon: Icons.location_city_rounded,
                                      label: 'Okul/Dershane',
                                      value: _getInstitutionName(),
                                      color: const Color(0xFFA855F7), // Purple
                                    ),
                                    
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
              );
            },
          ),
        ],
      ),
    );
  }
} 