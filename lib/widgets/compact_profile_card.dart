import 'package:flutter/material.dart';
import '../utils/app_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class CompactProfileCard extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final VoidCallback? onTap;
  
  const CompactProfileCard({
    super.key,
    this.userData,
    this.onTap,
  });

  @override
  State<CompactProfileCard> createState() => _CompactProfileCardState();
}

class _CompactProfileCardState extends State<CompactProfileCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_shimmerController);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
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
    final institution = widget.userData?['institution'];
    if (institution == null) return 'Belirtilmemiş';
    
    if (institution is Map<String, dynamic>) {
      return institution['name'] ?? 'Bilinmiyor';
    }
    
    return institution.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (widget.userData == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with avatar and main info
                    Row(
                      children: [
                        // Animated Avatar
                        AnimatedBuilder(
                          animation: _shimmerAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.primaryColor.withValues(alpha: 0.8),
                                    theme.primaryColor.withValues(alpha: 0.6),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDisplayName(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    AppIcons.verified,
                                    size: 16,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Performax Öğrencisi',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Action Icon
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            AppIcons.arrowForward,
                            size: 16,
                            color: theme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quick Info Row
                    Row(
                      children: [
                        // Class Info
                        if (widget.userData?['class'] != null) ...[
                          Expanded(
                            child: _buildQuickInfoTile(
                              icon: Icons.school_outlined,
                              label: 'Sınıf',
                              value: widget.userData!['class'],
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        
                        // Age Info
                        if (_getBirthDate() != null) ...[
                          Expanded(
                            child: _buildQuickInfoTile(
                              icon: Icons.cake_outlined,
                              label: 'Yaş',
                              value: '${_calculateAge(_getBirthDate())}',
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Institution Info
                    _buildQuickInfoTile(
                      icon: Icons.location_city_outlined,
                      label: 'Okul/Dershane',
                      value: _getInstitutionName(),
                      color: Colors.purple,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 