import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/institution.dart';
import '../models/avatar.dart';
import '../widgets/searchable_institution_dropdown.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/avatar_placeholder.dart';
import '../widgets/otp_verification_widget.dart';
import '../services/user_service.dart';
import '../services/sms_otp_service.dart';
import 'avatar_selection_screen.dart';

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
                  phoneNumber: _formattedPhoneNumber ?? _phoneNumberController.text,
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
        await _saveUserData(userCredential.user!.uid);
      }

      // Clear guest status when user successfully registers
      await UserService.clearGuestStatus();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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

  String? _validateClass(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen sınıfınızı seçin';
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

  String? _validateBirthDate(DateTime? date) {
    if (date == null) {
      return 'Lütfen doğum tarihinizi seçin';
    }
    
    final now = DateTime.now();
    final age = now.year - date.year;
    
    if (age < 10) {
      return 'Yaşınız en az 10 olmalıdır';
    }
    
    if (age > 100) {
      return 'Lütfen geçerli bir doğum tarihi girin';
    }
    
    return null;
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Lütfen cinsiyetinizi seçin';
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Adım 2/2',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Main content card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kişisel Bilgiler',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lütfen kişisel bilgilerinizi tamamlayın',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Full Name Field
                              TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Ad Soyad',
                                  hintText: 'Adınızı ve soyadınızı girin',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                keyboardType: TextInputType.name,
                                textCapitalization: TextCapitalization.words,
                                validator: _validateFullName,
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 20),
                              
                              // Phone Number Field
                              TextFormField(
                                controller: _phoneNumberController,
                                decoration: const InputDecoration(
                                  labelText: 'Telefon Numarası',
                                  hintText: '05551234567',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                                keyboardType: TextInputType.phone,
                                validator: _validatePhoneNumber,
                                enabled: !_isLoading,
                              ),
                              const SizedBox(height: 20),
                              
                              // Class Selection
                              DropdownButtonFormField<String>(
                                value: _selectedClass,
                                decoration: const InputDecoration(
                                  labelText: 'Sınıf',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: _classOptions.map((String className) {
                                  return DropdownMenuItem<String>(
                                    value: className,
                                    child: Text(className),
                                  );
                                }).toList(),
                                onChanged: _isLoading ? null : (value) {
                                  setState(() {
                                    _selectedClass = value;
                                  });
                                },
                                validator: _validateClass,
                              ),
                              const SizedBox(height: 20),
                              
                              // Gender Selection
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: const InputDecoration(
                                  labelText: 'Cinsiyet',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'male',
                                    child: Text('Erkek'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'female',
                                    child: Text('Kadın'),
                                  ),
                                ],
                                onChanged: _isLoading ? null : (value) {
                                  setState(() {
                                    _selectedGender = value;
                                    // Auto-select default avatar based on gender
                                    _selectedAvatarId ??= Avatar.getDefaultByGender(value).id;
                                  });
                                },
                                validator: _validateGender,
                              ),
                              const SizedBox(height: 20),
                              
                              // Avatar Selection
                              if (_selectedGender != null) ...[
                                const Text(
                                  'Avatar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: _isLoading ? null : () async {
                                    final selected = await Navigator.push<String>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AvatarSelectionScreen(
                                          userGender: _selectedGender!,
                                          currentAvatarId: _selectedAvatarId,
                                        ),
                                      ),
                                    );
                                    if (selected != null) {
                                      setState(() {
                                        _selectedAvatarId = selected;
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.primaryColor.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        if (_selectedAvatarId != null)
                                          AvatarPlaceholder(
                                            avatar: Avatar.getById(_selectedAvatarId),
                                            size: 60,
                                            showBorder: false,
                                          )
                                        else
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey[300],
                                            ),
                                            child: const Icon(
                                              Icons.person_add,
                                              color: Colors.grey,
                                              size: 30,
                                            ),
                                          ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _selectedAvatarId != null
                                                    ? Avatar.getById(_selectedAvatarId).displayName
                                                    : 'Avatar Seç',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _selectedAvatarId != null
                                                    ? 'Değiştirmek için dokun'
                                                    : 'Seni temsil edecek avatarı seç',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: theme.primaryColor,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                              ],
                              
                              // Date of Birth Field
                              DatePickerField(
                                labelText: 'Doğum Tarihi',
                                selectedDate: _selectedBirthDate,
                                onChanged: (date) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (mounted) {
                                      setState(() {
                                        _selectedBirthDate = date;
                                      });
                                    }
                                  });
                                },
                                validator: _validateBirthDate,
                                enabled: !_isLoading,
                                firstDate: DateTime(DateTime.now().year - 100),
                                lastDate: DateTime.now(),
                              ),
                              const SizedBox(height: 24),
                              
                              // Institution Selection Section
                              Text(
                                'Okul/Dershane Bilgisi',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Okulunuzu veya dershanenizi seçin',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Institution selection logic
                              if (!_useManualInstitution) ...[
                                SearchableInstitutionDropdown(
                                  labelText: 'Okul/Dershane Seçin',
                                  selectedInstitution: _selectedInstitution,
                                  onChanged: (institution) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          _selectedInstitution = institution;
                                        });
                                      }
                                    });
                                  },
                                  validator: _validateInstitution,
                                  enabled: !_isLoading,
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          _useManualInstitution = true;
                                          _selectedInstitution = null;
                                        });
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('Bulamıyorum, manuel gireceğim'),
                                ),
                              ] else ...[
                                // Manual Institution Input
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _manualInstitutionController,
                                    decoration: const InputDecoration(
                                      labelText: 'Okul/Dershane Adı',
                                      hintText: 'Okul veya dershane adını yazın',
                                      prefixIcon: Icon(Icons.school),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.transparent,
                                    ),
                                    validator: _validateManualInstitution,
                                    enabled: !_isLoading,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: _isLoading ? null : () {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() {
                                          _useManualInstitution = false;
                                          _manualInstitutionController.clear();
                                        });
                                      }
                                    });
                                  },
                                  icon: const Icon(Icons.search),
                                  label: const Text('Listeden seç'),
                                ),
                              ],
                              const SizedBox(height: 32),
                              
                              // Complete Registration Button
                              // OTP will be sent automatically when form is submitted
                              if (_isLoading || _isSendingOtp)
                                const Center(child: CircularProgressIndicator())
                              else
                                Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _completeRegistration,
                                        icon: const Icon(Icons.check_circle_outline),
                                        label: const Text('Kaydı Tamamla'),
                                        style: ElevatedButton.styleFrom(
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
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(Icons.arrow_back),
                                        label: const Text('Geri Dön'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 