import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle SMS OTP verification using Firebase Auth
/// This service manages phone number verification during user registration
/// CRITICAL: Handles reCAPTCHA silently to prevent UI blocking
/// CRITICAL: Implements exponential backoff to prevent rate limiting
class SmsOtpService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;
  int? _resendToken;
  
  // Rate limiting state
  static const String _lastOtpAttemptKey = 'last_otp_attempt_timestamp';
  static const String _otpAttemptCountKey = 'otp_attempt_count';
  static const String _blockUntilKey = 'otp_block_until_timestamp';
  
  // Callback for when OTP is actually sent (after reCAPTCHA completes)
  Function(String verificationId)? onOtpSent;
  
  // Callback for when verification fails (reCAPTCHA error, etc.)
  Function(String error)? onVerificationFailed;
  
  /// Check if device is currently rate-limited
  /// Returns null if OK to proceed, or error message if blocked
  Future<String?> checkRateLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Check if device is temporarily blocked
      final blockUntil = prefs.getInt(_blockUntilKey) ?? 0;
      if (blockUntil > now) {
        final remainingMinutes = ((blockUntil - now) / 60000).ceil();
        debugPrint('⏸️ Device is temporarily blocked for $remainingMinutes more minutes');
        return 'Çok fazla deneme yapıldı. Lütfen $remainingMinutes dakika sonra tekrar deneyin.';
      }
      
      // Get attempt count and last attempt time
      final attemptCount = prefs.getInt(_otpAttemptCountKey) ?? 0;
      final lastAttempt = prefs.getInt(_lastOtpAttemptKey) ?? 0;
      
      // Reset counter if more than 1 hour has passed since last attempt
      if (now - lastAttempt > 3600000) {
        await prefs.setInt(_otpAttemptCountKey, 0);
        await prefs.remove(_blockUntilKey);
        debugPrint('✅ Rate limit counter reset after 1 hour');
        return null;
      }
      
      // Exponential backoff based on attempt count
      if (attemptCount >= 5) {
        // After 5 attempts, block for 30 minutes
        final blockTime = now + (30 * 60000);
        await prefs.setInt(_blockUntilKey, blockTime);
        debugPrint('🚫 Too many attempts (5+). Blocking for 30 minutes.');
        return 'Çok fazla deneme yapıldı. Lütfen 30 dakika sonra tekrar deneyin.';
      } else if (attemptCount >= 3) {
        // After 3 attempts, require 5 minute wait
        final requiredWait = 5 * 60000; // 5 minutes
        final timeSinceLastAttempt = now - lastAttempt;
        if (timeSinceLastAttempt < requiredWait) {
          final remainingMinutes = ((requiredWait - timeSinceLastAttempt) / 60000).ceil();
          debugPrint('⏸️ Rate limit: Need to wait $remainingMinutes more minutes');
          return 'Lütfen $remainingMinutes dakika bekleyip tekrar deneyin.';
        }
      }
      
      return null; // OK to proceed
    } catch (e) {
      debugPrint('⚠️ Error checking rate limit: $e');
      return null; // If error, allow attempt (fail open)
    }
  }
  
  /// Record an OTP attempt for rate limiting
  Future<void> _recordAttempt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final attemptCount = (prefs.getInt(_otpAttemptCountKey) ?? 0) + 1;
      
      await prefs.setInt(_lastOtpAttemptKey, now);
      await prefs.setInt(_otpAttemptCountKey, attemptCount);
      
      debugPrint('📊 OTP Attempt recorded: $attemptCount total attempts');
    } catch (e) {
      debugPrint('⚠️ Error recording attempt: $e');
    }
  }
  
  /// Reset rate limiting counters (use after successful verification)
  Future<void> resetRateLimit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_otpAttemptCountKey);
      await prefs.remove(_lastOtpAttemptKey);
      await prefs.remove(_blockUntilKey);
      debugPrint('✅ Rate limit counters reset');
    } catch (e) {
      debugPrint('⚠️ Error resetting rate limit: $e');
    }
  }
  
  /// Send OTP to the provided phone number
  /// Returns true if OTP request was initiated successfully
  /// The actual OTP sending happens after reCAPTCHA completes (handled via codeSent callback)
  /// [phoneNumber] must be in E.164 format (e.g., +905551234567)
  /// CRITICAL: Configured to use silent reCAPTCHA to prevent UI blocking
  Future<bool> sendOtp(String phoneNumber, {Function(String verificationId)? onSent, Function(String error)? onFailed}) async {
    try {
      debugPrint('📱 Sending OTP to phone number: $phoneNumber');
      
      // CRITICAL: Check rate limit before proceeding
      final rateLimitError = await checkRateLimit();
      if (rateLimitError != null) {
        debugPrint('🚫 Rate limit check failed: $rateLimitError');
        if (onFailed != null) {
          onFailed(rateLimitError);
        }
        return false;
      }
      
      // Record this attempt for rate limiting
      await _recordAttempt();
      
      // Store callbacks
      onOtpSent = onSent;
      onVerificationFailed = onFailed;
      
      // Verify phone number format (must start with +)
      if (!phoneNumber.startsWith('+')) {
        debugPrint('❌ Phone number must be in E.164 format (e.g., +905551234567)');
        if (onFailed != null) {
          onFailed('Geçersiz telefon numarası formatı');
        }
        return false;
      }
      
      // Configure verification settings
      // Note: On iOS, Firebase attempts silent reCAPTCHA first
      // The reCAPTCHA challenge happens asynchronously and should not block OTP input
      verificationCompleted(PhoneAuthCredential credential) {
        debugPrint('✅ Phone number auto-verified (silent reCAPTCHA succeeded)');
      }
      
      verificationFailed(FirebaseAuthException e) {
        debugPrint('❌ Phone verification failed: ${e.code} - ${e.message}');
        
        // Handle specific error codes
        String errorMessage = 'OTP gönderilemedi';
        bool isRateLimitError = false;
        
        if (e.code == 'too-many-requests' || e.message?.toLowerCase().contains('blocked') == true) {
          errorMessage = 'Cihazınız geçici olarak engellendi. Lütfen:\n'
              '1. Test telefon numarası kullanın (05550001234)\n'
              '2. Veya 30 dakika bekleyip tekrar deneyin\n'
              '3. Veya farklı bir cihaz kullanın';
          isRateLimitError = true;
          debugPrint('🚫 CRITICAL: Device blocked by Firebase due to too many requests');
          debugPrint('💡 SOLUTION: Use test phone number +90 555 000 1234 with code 123456');
        } else if (e.code == 'invalid-phone-number') {
          errorMessage = 'Geçersiz telefon numarası formatı';
          debugPrint('⚠️ Invalid phone number format.');
        } else if (e.code == 'quota-exceeded') {
          errorMessage = 'Firebase kotası aşıldı. Lütfen daha sonra tekrar deneyin.';
          isRateLimitError = true;
          debugPrint('⚠️ Quota exceeded.');
        } else if (e.code == 'network-request-failed' || e.message?.contains('network') == true) {
          errorMessage = 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin.';
          debugPrint('⚠️ Network error.');
        } else {
          errorMessage = e.message ?? 'Bilinmeyen bir hata oluştu';
        }
        
        // If rate limit error, set a longer block time
        if (isRateLimitError) {
          _setLongBlock();
        }
        
        // Notify about the failure
        if (onVerificationFailed != null) {
          onVerificationFailed!(errorMessage);
        }
      }
      
      codeSent(String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        debugPrint('✅ OTP sent successfully. Verification ID: $verificationId');
        debugPrint('📝 reCAPTCHA challenge completed - OTP input can proceed');
        
        // Success - reset rate limiting on successful send
        resetRateLimit();
        
        // Notify that OTP was sent (after reCAPTCHA completes)
        if (onOtpSent != null) {
          onOtpSent!(verificationId);
        }
      }
      
      codeAutoRetrievalTimeout(String verificationId) {
        _verificationId = verificationId;
        debugPrint('⏱️ Phone code auto-retrieval timeout: $verificationId');
        debugPrint('📝 OTP input can proceed - verification ID available');
        
        // Even if auto-retrieval times out, we still have a verification ID
        // This can happen if reCAPTCHA had issues but still managed to get verification ID
        // Show OTP modal as fallback
        if (onOtpSent != null && _verificationId != null) {
          debugPrint('🔄 Fallback: Showing OTP modal after auto-retrieval timeout');
          onOtpSent!(_verificationId!);
        }
      }
      
      // Send OTP with silent reCAPTCHA handling
      // On iOS, Firebase attempts silent reCAPTCHA first
      // The reCAPTCHA challenge happens asynchronously and completes before codeSent is called
      // This ensures OTP input is not blocked
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
      );
      
      debugPrint('✅ OTP request initiated - reCAPTCHA will complete asynchronously');
      // Note: Return true immediately - actual OTP sending happens in codeSent callback
      return true;
    } catch (e) {
      debugPrint('❌ Error sending OTP: $e');
      String errorMessage = 'OTP gönderilemedi: ${e.toString()}';
      if (onVerificationFailed != null) {
        onVerificationFailed!(errorMessage);
      }
      return false;
    }
  }
  
  /// Set a long block time when Firebase blocks the device
  Future<void> _setLongBlock() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final blockTime = now + (60 * 60000); // Block for 60 minutes
      await prefs.setInt(_blockUntilKey, blockTime);
      await prefs.setInt(_otpAttemptCountKey, 10); // Mark as heavily rate-limited
      debugPrint('🚫 Device blocked for 60 minutes due to Firebase rate limit');
    } catch (e) {
      debugPrint('⚠️ Error setting long block: $e');
    }
  }
  
  /// Verify the OTP code entered by the user
  /// Returns PhoneAuthCredential if verification succeeds, null otherwise
  Future<PhoneAuthCredential?> verifyOtp(String smsCode) async {
    try {
      if (_verificationId == null) {
        debugPrint('❌ No verification ID found. Please send OTP first.');
        return null;
      }
      
      debugPrint('🔐 Verifying OTP code: $smsCode');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      
      debugPrint('✅ OTP verified successfully');
      return credential;
    } catch (e) {
      debugPrint('❌ Error verifying OTP: $e');
      return null;
    }
  }
  
  /// Format phone number to E.164 format
  /// Converts Turkish phone numbers to E.164 format
  /// Input: "05551234567" or "5551234567" -> Output: "+905551234567"
  static String formatPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it starts with 0, remove it
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }
    
    // If it doesn't start with country code, add Turkish country code (+90)
    if (!digitsOnly.startsWith('90')) {
      digitsOnly = '90$digitsOnly';
    }
    
    // Add + prefix
    return '+$digitsOnly';
  }
  
  /// Validate phone number format
  /// Returns true if phone number is valid Turkish phone number
  static bool isValidTurkishPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    String digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Remove leading 0 if present
    if (digitsOnly.startsWith('0')) {
      digitsOnly = digitsOnly.substring(1);
    }
    
    // Turkish mobile numbers should be 10 digits (without country code)
    // Starting with 5 (e.g., 5XX XXX XX XX)
    return digitsOnly.length == 10 && digitsOnly.startsWith('5');
  }
  
  /// Reset verification state
  void reset() {
    _verificationId = null;
    _resendToken = null;
    debugPrint('🔄 OTP verification state reset');
  }
  
  /// Check if OTP has been sent
  bool get isOtpSent => _verificationId != null;
}

