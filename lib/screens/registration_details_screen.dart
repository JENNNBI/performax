import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:provider/provider.dart'; // Import Provider
import 'package:shared_preferences/shared_preferences.dart'; // For streak popup flag
import '../models/institution.dart';
import '../models/avatar.dart';
import '../services/user_provider.dart'; // Import UserProvider
import '../widgets/searchable_institution_dropdown.dart';
import '../widgets/otp_verification_widget.dart';
import '../services/user_service.dart';
import '../services/sms_otp_service.dart';
import '../services/quest_service.dart';
import 'avatar_selection_screen.dart';
import 'home_screen.dart'; // Import HomeScreen

class RegistrationDetailsScreen extends StatefulWidget {
  static const String id = '/registration_details';
  
  final String email;
  final String password;
  
  const RegistrationDetailsScreen({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<RegistrationDetailsScreen> createState() => _RegistrationDetailsScreenState();
}

class _RegistrationDetailsScreenState extends State<RegistrationDetailsScreen> 
    with SingleTickerProviderStateMixin {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _manualInstitutionController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  String? _selectedClass;
  String? _selectedGender;
  String? _selectedStudyField; // 'Sayısal', 'Eşit Ağırlık', 'Sözel'
  String? _selectedAvatarId;
  Institution? _selectedInstitution;
  DateTime? _selectedBirthDate;
  bool _useManualInstitution = false;
  
  // Phone verification state
  bool _isPhoneVerified = false;
  bool _isSendingOtp = false;
  String? _formattedPhoneNumber;
  final SmsOtpService _otpService = SmsOtpService();
  
  /// Show OTP verification modal dialog
  Future<bool> _showOtpVerificationModal() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismissing without verification
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'SMS doğrulama kodunu giriniz!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formattedPhoneNumber ?? _phoneNumberController.text} numarasına gönderilen 6 haneli kodu girin',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                
                // OTP Verification Widget
                OtpVerificationWidget(
                  phoneNumber: _formattedPhoneNumber?.isNotEmpty == true 
                      ? _formattedPhoneNumber 
                      : (_phoneNumberController.text.isNotEmpty ? _phoneNumberController.text : null),
                  onVerificationComplete: (otp) async {
                    await _verifyOtp(otp);
                    if (_isPhoneVerified && mounted && context.mounted) {
                      Navigator.of(context).pop(true); // Return true on success
                    }
                  },
                  onResendOtp: () async {
                    await _resendOtp();
                  },
                  isLoading: false, // CRITICAL: Never block input in modal - OTP is already sent
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false;
  }
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _classOptions = [
    '9. Sınıf',
    '10. Sınıf', 
    '11. Sınıf',
    '12. Sınıf',
    'Mezun',
  ];

  final List<String> _studyFieldOptions = [
    'Sayısal',
    'Eşit Ağırlık',
    'Sözel',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
    
    // Sync avatar selection with provider if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        
        // Sync local state with provider if already set
        if (userProvider.currentAvatarId != null) {
          setState(() {
            _selectedAvatarId = userProvider.currentAvatarId;
          });
          debugPrint('🔄 Registration: Synced avatar from provider: ${userProvider.currentAvatarId}');
        }
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _manualInstitutionController.dispose();
    _phoneNumberController.dispose();
    _otpService.reset();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _sendOtp() async {
    final phoneNumber = _phoneNumberController.text.trim();
    
    // Validate phone number format
    if (!SmsOtpService.isValidTurkishPhoneNumber(phoneNumber)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Geçerli bir Türk telefon numarası girin (örn: 05551234567)'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isSendingOtp = true;
    });
    
    try {
      _formattedPhoneNumber = SmsOtpService.formatPhoneNumber(phoneNumber);
      
      // Send OTP - the callback will be called after reCAPTCHA completes
      final success = await _otpService.sendOtp(
        _formattedPhoneNumber!,
        onSent: (verificationId) {
          // OTP sent successfully after reCAPTCHA completes
          if (mounted) {
            setState(() {
              _isSendingOtp = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP kodu gönderildi'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      );
      
      if (mounted) {
        if (!success) {
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP gönderilemedi. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingOtp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  Future<void> _verifyOtp(String otp) async {
    try {
      final credential = await _otpService.verifyOtp(otp);
      
      if (credential != null) {
        setState(() {
          _isPhoneVerified = true;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telefon numarası başarıyla doğrulandı!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception('Invalid OTP');
      }
    } catch (e) {
      setState(() {
        _isPhoneVerified = false;
      });
      
      if (mounted) {
        // Show "yanlış kod" pop-up dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Hata'),
              content: const Text('yanlış kod'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Tamam'),
                ),
              ],
            );
          },
        );
      }
      rethrow;
    }
  }
  
  Future<void> _resendOtp() async {
    await _sendOtp();
  }

  Future<void> _completeRegistration() async {
    // Prevent multiple submissions
    if (_isLoading || _isSendingOtp) {
      return;
    }

    // CRITICAL: Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // CRITICAL: Block registration until phone is verified
    if (!_isPhoneVerified) {
      // Auto-send OTP and show verification modal
      final phoneNumber = _phoneNumberController.text.trim();
      
      // Validate phone number format
      if (!SmsOtpService.isValidTurkishPhoneNumber(phoneNumber)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Geçerli bir Türk telefon numarası girin (örn: 05551234567)'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      
      setState(() {
        _isSendingOtp = true;
      });
      
      // Add a timeout fallback - if reCAPTCHA takes too long or user navigates back,
      // show OTP modal anyway after a reasonable delay
      Timer? timeoutTimer;
      bool modalShown = false;
      
      try {
        _formattedPhoneNumber = SmsOtpService.formatPhoneNumber(phoneNumber);
        
        // Set a timeout to show OTP modal as fallback (15 seconds)
        // This handles cases where reCAPTCHA fails silently or user navigates back
        timeoutTimer = Timer(const Duration(seconds: 15), () {
          if (mounted && !modalShown && _otpService.isOtpSent) {
            debugPrint('⏱️ Timeout fallback: Showing OTP modal despite reCAPTCHA issues');
            modalShown = true;
            _showOtpVerificationModal().then((verified) {
              if (mounted) {
                if (verified) {
                  setState(() {
                    _isSendingOtp = false;
                  });
                  _proceedWithRegistration();
                } else {
                  setState(() {
                    _isSendingOtp = false;
                  });
                }
              }
            });
          }
        });
        
        // Send OTP and wait for codeSent callback before showing modal
        // This ensures reCAPTCHA completes before OTP input modal appears
        // The modal will only appear AFTER reCAPTCHA challenge completes
        // CRITICAL: Also handle reCAPTCHA failures and show OTP modal as fallback
        final success = await _otpService.sendOtp(
          _formattedPhoneNumber!,
          onSent: (verificationId) async {
            // Cancel timeout timer since we got the callback
            timeoutTimer?.cancel();
            
            // CRITICAL: Reset loading state - OTP has been sent, modal can now show
            // This ensures input fields are not blocked
            if (mounted) {
              setState(() {
                _isSendingOtp = false;
              });
            }
            
            // CRITICAL: This callback is called AFTER reCAPTCHA completes
            // Only show OTP modal after reCAPTCHA is done
            if (mounted && !modalShown) {
              modalShown = true;
              final verified = await _showOtpVerificationModal();
              
              if (mounted) {
                if (!verified) {
                  // User closed modal without verifying or verification failed
                  setState(() {
                    _isSendingOtp = false;
                  });
                } else {
                  // OTP verified successfully, continue with registration
                  setState(() {
                    _isSendingOtp = false;
                  });
                  // Continue with actual registration (don't call _completeRegistration again)
                  await _proceedWithRegistration();
                }
              }
            }
          },
          onFailed: (errorMessage) async {
            // Cancel timeout timer
            timeoutTimer?.cancel();
            
            // CRITICAL: Reset loading state
            if (mounted) {
              setState(() {
                _isSendingOtp = false;
              });
            }
            
            // CRITICAL: Handle reCAPTCHA failures (e.g., "page not found" error)
            // Even if reCAPTCHA fails, we should still try to show OTP modal
            // Sometimes Firebase still sends the OTP even if reCAPTCHA had issues
            debugPrint('⚠️ reCAPTCHA verification failed: $errorMessage');
            
            if (mounted && !modalShown) {
              // Check if we have a verification ID despite the error
              // Sometimes Firebase still processes the request even after reCAPTCHA errors
              if (_otpService.isOtpSent) {
                debugPrint('✅ Verification ID available despite reCAPTCHA error - showing OTP modal');
                modalShown = true;
                // Show OTP modal even if reCAPTCHA failed
                final verified = await _showOtpVerificationModal();
                
                if (mounted) {
                  if (!verified) {
                    setState(() {
                      _isSendingOtp = false;
                    });
                  } else {
                    setState(() {
                      _isSendingOtp = false;
                    });
                    await _proceedWithRegistration();
                  }
                }
              } else {
                // No verification ID - show error and allow retry
                setState(() {
                  _isSendingOtp = false;
                });
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Tekrar Dene',
                      textColor: Colors.white,
                      onPressed: () {
                        // Retry sending OTP
                        _completeRegistration();
                      },
                    ),
                  ),
                );
              }
            }
          },
        );
        
        if (mounted) {
          if (!success) {
            timeoutTimer.cancel();
            setState(() {
              _isSendingOtp = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP gönderilemedi. Lütfen tekrar deneyin.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          // Don't show modal here - wait for codeSent callback
          // The modal will be shown from the onSent callback AFTER reCAPTCHA completes
          // OR from onFailed callback if reCAPTCHA fails but verification ID is available
          // OR from timeout timer if reCAPTCHA takes too long
        }
      } catch (e) {
        timeoutTimer?.cancel();
        if (mounted) {
          setState(() {
            _isSendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      return; // Exit early - registration will continue after OTP verification
    }
    
    // If phone is already verified, proceed with registration
    await _proceedWithRegistration();
  }
  
  /// Proceed with actual Firebase user creation and data saving
  /// This is called only after phone verification is complete
  Future<void> _proceedWithRegistration() async {
    // Proceed with registration only if phone is verified
    if (!_isPhoneVerified) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;

        // 1. Enforce Clean Slate immediately
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.clearSession();
        
        // 2. Prepare Fresh User Profile

        // 3. Save to Firestore
        // Note: _saveUserData uses 'set', effectively overwriting/creating new doc
        // We will call it, but we need to ensure it uses our 'userProfile' object values
        // or we manually update the fields inside _saveUserData to match our strict defaults.
        // Actually, _saveUserData constructs the map from controllers.
        // Let's rely on _saveUserData but pass the ID.
        // Wait, _saveUserData doesn't take UserProfile object, it takes userId.
        // We should ensure _saveUserData writes the correct rocket/score values.
        
        // Let's modify _saveUserData call or update the map it writes.
        // For now, let's just manually write the critical gamification stats to Firestore here
        // or update _saveUserData to include them.
        // Since _saveUserData is complex, let's call it, then update the gamification stats explicitly.
        
        // Clear old quest data for new user
        await QuestService.instance.resetLocalData();
        
        await _saveUserData(uid); // This saves profile info
        
        // Explicitly set gamification defaults in Firestore
        await _firestore.collection('users').doc(uid).update({
          'rocketCurrency': 100,
          'leaderboardScore': 100,
        });
        
        // 4. 🎯 CRITICAL: Initialize UserProvider with user-specific data
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📝 REGISTRATION: Initializing UserProvider');
        debugPrint('   User ID: $uid');
        debugPrint('   Avatar ID: $_selectedAvatarId');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // First, load the user session (sets _currentUserId)
        await userProvider.loadUserData(uid);
        debugPrint('✅ Step 1: User session loaded');
        
        // Set avatar in provider if selected
        if (_selectedAvatarId != null) {
          final avatar = Avatar.getById(_selectedAvatarId!);
          debugPrint('   Avatar Path: ${avatar.bust2DPath}');
          
          // 🎯 CRITICAL: Save avatar WITH userId
          await userProvider.saveAvatar(
            avatar.bust2DPath, 
            _selectedAvatarId!,
            userId: uid, // Explicitly pass userId
          );
          debugPrint('✅ Step 2: Avatar saved with user-specific keys');
        }
        
        // Update gamification stats in provider
        await userProvider.updateStats(
          score: 100,
          rockets: 100,
          rank: 1982,
        );
        debugPrint('✅ Step 3: Stats initialized');
        
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('✅ REGISTRATION COMPLETE - UserProvider ready');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // Force refresh user profile to cache it locally immediately
        await UserService().getCurrentUserProfile(forceRefresh: true);
      }

      // Clear guest status when user successfully registers
      await UserService.clearGuestStatus();

      // Reload quests based on the newly cached profile
      await QuestService.instance.loadQuests();

      // 🎯 CRITICAL: Mark "Daily Login" quest as COMPLETED (but NOT claimed)
      // This is for NEW USER REGISTRATION ONLY
      // The quest will show as "Completed" with a green "Claim" button
      // User MUST manually tap "Topla" to receive the reward
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🎁 NEW USER: Marking Daily Login Quest as Completed');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      await QuestService.instance.markDailyLoginAsCompleted();
      debugPrint('✅ Daily Login quest ready to claim (user must tap button)');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // 🎯 CRITICAL: Mark this as a NEW REGISTRATION for Streak popup
      // This flag will trigger the Streak Day 1 popup on HomeScreen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_first_streak_popup', true);
      debugPrint('🎊 NEW USER: Flagged for Streak Day 1 celebration popup');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Kayıt başarısız'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt sırasında hata oluştu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': widget.email,
        'fullName': _fullNameController.text.trim(),
        'phoneNumber': _formattedPhoneNumber, // Store formatted phone number
        'isPhoneVerified': _isPhoneVerified, // Store verification status
        'class': _selectedClass,
        'studyField': _selectedStudyField, // Store selected field of study
        'gender': _selectedGender,
        'avatar': _selectedAvatarId != null 
            ? {
                'id': _selectedAvatarId,
                'selectedDate': FieldValue.serverTimestamp(),
              }
            : null,
        'registrationDate': FieldValue.serverTimestamp(),
        'birthDate': _selectedBirthDate != null 
            ? Timestamp.fromDate(_selectedBirthDate!)
            : null,
        'institution': _useManualInstitution 
            ? {
                'name': _manualInstitutionController.text.trim(),
                'type': 'manual',
                'isManual': true,
              }
            : _selectedInstitution?.toJson(),
        'profile': {
          'isComplete': true,
          'setupStep': 'completed',
        },
      });
    } catch (e) {
      debugPrint('Error saving user data: $e');
      rethrow;
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ad soyad gereklidir';
    }
    if (value.trim().length < 2) {
      return 'Ad soyad en az 2 karakter olmalıdır';
    }
    return null;
  }


  String? _validateInstitution(Institution? institution) {
    if (!_useManualInstitution && institution == null) {
      return 'Lütfen okulunuzu/dershanenizi seçin veya manuel giriş yapın';
    }
    return null;
  }

  String? _validateManualInstitution(String? value) {
    if (_useManualInstitution && (value == null || value.trim().isEmpty)) {
      return 'Lütfen okul/dershane adını girin';
    }
    return null;
  }


  
  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon numarası gereklidir';
    }
    
    if (!SmsOtpService.isValidTurkishPhoneNumber(value.trim())) {
      return 'Geçerli bir Türk telefon numarası girin (örn: 05551234567)';
    }
    
    return null;
  }


  @override
  Widget build(BuildContext context) {
    // Dark Theme / Gamified Aesthetic
    // Primary Color: Deep Blue (0xFF0F172A) or similar dark shade
    // Accent Color: Neon Blue/Cyan
    
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Deep Blue Background
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Header (No Progress Bar needed if it looks clunky, but let's keep it subtle)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: const Text(
                      'Step 2/2',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Title
                const Text(
                  'Personal Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your gamer profile to start.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _ModernTextField(
                        controller: _fullNameController,
                        label: 'Full Name',
                        icon: Icons.person_rounded,
                        validator: _validateFullName,
                      ),
                      const SizedBox(height: 20),
                      
                      // Phone Number
                      _ModernTextField(
                        controller: _phoneNumberController,
                        label: 'Phone Number',
                        icon: Icons.phone_iphone_rounded,
                        inputType: TextInputType.phone,
                        validator: _validatePhoneNumber,
                      ),
                      const SizedBox(height: 20),
                      
                      // Class Selection
                      _ModernDropdown(
                        value: _selectedClass,
                        label: 'Class',
                        icon: Icons.school_rounded,
                        items: _classOptions,
                        onChanged: _isLoading ? null : (val) {
                          setState(() {
                             _selectedClass = val;
                             if (val == '9. Sınıf' || val == '10. Sınıf') _selectedStudyField = null;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Study Field (Conditional)
                      if (_selectedClass == '11. Sınıf' || _selectedClass == '12. Sınıf' || _selectedClass == 'Mezun') ...[
                        _ModernDropdown(
                          value: _selectedStudyField,
                          label: 'Field of Study',
                          icon: Icons.category_rounded,
                          items: _studyFieldOptions,
                          onChanged: _isLoading ? null : (val) => setState(() => _selectedStudyField = val),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Gender
                      _ModernDropdown(
                        value: _selectedGender,
                        label: 'Gender',
                        icon: Icons.transgender_rounded, // or person
                        items: const ['male', 'female'], // You might want to map these to 'Erkek'/'Kadın' for display
                        displayMap: const {'male': 'Erkek', 'female': 'Kadın'},
                        onChanged: _isLoading ? null : (val) {
                          setState(() {
                            _selectedGender = val;
                            // 🎯 INSTANT AVATAR UPDATE: Set default avatar for selected gender
                            // This triggers immediate visual feedback in the avatar preview below
                            final defaultAvatar = Avatar.getDefaultByGender(val!);
                            _selectedAvatarId = defaultAvatar.id;
                            
                            // Also update UserProvider immediately for instant UI sync
                            // This updates RAM only (no userId yet during registration)
                            final userProvider = Provider.of<UserProvider>(context, listen: false);
                            userProvider.saveAvatar(
                              defaultAvatar.bust2DPath,
                              defaultAvatar.id,
                            );
                            
                            debugPrint('🎨 Gender Selected: $val → Avatar Updated: ${defaultAvatar.displayName}');
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Avatar Selection (Action Tile)
                      if (_selectedGender != null) ...[
                        Consumer<UserProvider>(
                          builder: (context, userProvider, child) {
                            final displayId = userProvider.currentAvatarId ?? _selectedAvatarId;
                            final displayPath = userProvider.currentAvatarPath ?? 
                                (displayId != null ? Avatar.getById(displayId).bust2DPath : null);
                            
                            return GestureDetector(
                              onTap: () async {
                                final selected = await Navigator.push<String>(
                                  context, 
                                  MaterialPageRoute(builder: (_) => AvatarSelectionScreen(userGender: _selectedGender!, currentAvatarId: displayId))
                                );
                                if (selected != null) setState(() => _selectedAvatarId = selected);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)), // Glowing border
                                ),
                                child: Row(
                                  children: [
                                    // 🎯 ANIMATED AVATAR PREVIEW: Smooth transition when gender changes
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 400),
                                      transitionBuilder: (Widget child, Animation<double> animation) {
                                        // Combine fade + scale for premium feel
                                        return FadeTransition(
                                          opacity: animation,
                                          child: ScaleTransition(
                                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutBack,
                                              ),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        key: ValueKey(displayPath ?? 'no_avatar'), // CRITICAL: Key for AnimatedSwitcher
                                        width: 64, height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.cyanAccent, width: 2),
                                          boxShadow: [
                                            BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.2), blurRadius: 10),
                                          ],
                                          image: displayPath != null ? DecorationImage(
                                            image: AssetImage(displayPath),
                                            fit: BoxFit.cover,
                                            alignment: Alignment.topCenter,
                                          ) : null,
                                          color: Colors.grey[800],
                                        ),
                                        child: displayPath == null ? const Icon(Icons.add, color: Colors.white) : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            displayId != null ? Avatar.getById(displayId).displayName : 'Select Avatar',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to change character',
                                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Date Picker (Action Tile Style)
                       GestureDetector(
                         onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
                              firstDate: DateTime(1950),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.dark().copyWith(
                                    colorScheme: const ColorScheme.dark(primary: Colors.cyanAccent),
                                  ),
                                  child: child!,
                                );
                              }
                            );
                            if (date != null) setState(() => _selectedBirthDate = date);
                         },
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                           decoration: BoxDecoration(
                             color: Colors.white.withValues(alpha: 0.05),
                             borderRadius: BorderRadius.circular(30),
                             border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                           ),
                           child: Row(
                             children: [
                               Icon(Icons.calendar_today_rounded, color: Colors.white.withValues(alpha: 0.7)),
                               const SizedBox(width: 12),
                               Text(
                                 _selectedBirthDate == null 
                                   ? 'Date of Birth' 
                                   : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                                 style: TextStyle(
                                   color: _selectedBirthDate == null ? Colors.white54 : Colors.white,
                                   fontSize: 16,
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                       
                       const SizedBox(height: 24),

                       // Institution / School Selection
                       if (!_useManualInstitution) ...[
                          SearchableInstitutionDropdown(
                            labelText: 'School / Institution',
                            hintText: 'Search for your school...',
                            selectedInstitution: _selectedInstitution,
                            onChanged: _isLoading ? (_) {} : (inst) => setState(() => _selectedInstitution = inst),
                            validator: _validateInstitution,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : () => setState(() {
                                _useManualInstitution = true;
                                _selectedInstitution = null;
                              }),
                              child: Text(
                                "I can't find it, I will enter manually",
                                style: TextStyle(
                                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                       ] else ...[
                          // Manual Entry
                          _ModernTextField(
                            controller: _manualInstitutionController,
                            label: 'School Name',
                            icon: Icons.school_rounded,
                            validator: _validateManualInstitution,
                          ),
                          const SizedBox(height: 8),
                           Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _isLoading ? null : () => setState(() {
                                _useManualInstitution = false;
                                _manualInstitutionController.clear();
                              }),
                              child: Text(
                                "Back to List Search",
                                style: TextStyle(
                                  color: Colors.cyanAccent.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                       ],

                       const SizedBox(height: 40),

                       // Action Button
                      if (_isLoading || _isSendingOtp)
                        const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                      else
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00E5FF), Color(0xFF2979FF)], // Cyan to Blue
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: const Color(0xFF2979FF).withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _completeRegistration,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text(
                              'Complete Registration',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                        
                       const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Modern Widgets
class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType inputType;
  final String? Function(String?)? validator;

  const _ModernTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.inputType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white), // Input text color
      validator: validator,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.cyanAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
    );
  }
}

class _ModernDropdown extends StatelessWidget {
  final String? value;
  final String label;
  final IconData icon;
  final List<String> items;
  final Map<String, String>? displayMap;
  final Function(String?)? onChanged;

  const _ModernDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    this.displayMap,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            displayMap?[item] ?? item,
            style: const TextStyle(color: Colors.white), // Dropdown item text
          ),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: const Color(0xFF1E293B), // Dark dropdown menu
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      ),
      style: const TextStyle(color: Colors.white), // Selected text color
    );
  }
} 