import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// OTP Verification Widget
/// Redesigned with Glassmorphism and Gamer Aesthetic
class OtpVerificationWidget extends StatefulWidget {
  final String phoneNumber;
  final Function(String otp) onVerificationComplete;
  final Function() onResendOtp;
  final bool isLoading;
  
  const OtpVerificationWidget({
    super.key,
    required this.phoneNumber,
    required this.onVerificationComplete,
    required this.onResendOtp,
    this.isLoading = false,
  });

  @override
  State<OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<OtpVerificationWidget> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  String _errorMessage = '';
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes[0].canRequestFocus) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) controller.dispose();
    for (var node in _focusNodes) node.dispose();
    super.dispose();
  }

  void _onOtpChanged(int index, String value) {
    if (value.length == 1) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _verifyOtp();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    
    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter full code');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });

    try {
      await widget.onVerificationComplete(otp);
    } catch (e) {
      setState(() {
        _errorMessage = 'Invalid Code';
        _isVerifying = false;
      });
      for (var controller in _controllers) controller.clear();
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: RenderFlex Overflow & Layout Crash
    // We wrap the entire content in SingleChildScrollView to handle small screens/keyboard.
    // We also use Flexible/Expanded carefully inside Row.
    
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Opaque Deep Blue to cover any white dialog bg
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_person_rounded, color: Colors.cyanAccent, size: 32),
            ),
            const SizedBox(height: 16),
            
            // Title
            const Text(
              'Verification Code',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Enter the code sent to',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.phoneNumber,
              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            // 6 Separate Square Input Boxes
            // FIX: Use Wrap or flexible sizing to prevent overflow on small screens
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate max width for boxes to fit
                final availableWidth = constraints.maxWidth;
                final boxWidth = (availableWidth - (5 * 8)) / 6; // 5 gaps of 8px
                final clampedSize = boxWidth.clamp(30.0, 44.0);
                
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildDigitBox(index, clampedSize)),
                );
              },
            ),
            
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Actions
            if (_isVerifying)
              const CircularProgressIndicator(color: Colors.cyanAccent)
            else
              TextButton(
                onPressed: widget.onResendOtp,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 16, color: Colors.white.withOpacity(0.7)),
                    const SizedBox(width: 8),
                    const Text(
                      "I didn't receive code",
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index, double size) {
    // Check if this box is active (focused) or filled
    final isFocused = _focusNodes[index].hasFocus;
    final isFilled = _controllers[index].text.isNotEmpty;
    
    return Container(
      width: size,
      height: size * 1.2, // Slightly taller than wide
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused || isFilled 
              ? Colors.cyanAccent 
              : Colors.white.withOpacity(0.1),
          width: isFocused ? 2 : 1,
        ),
        boxShadow: isFocused 
            ? [BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 8, spreadRadius: 1)] 
            : [],
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.5, // Responsive font size
          fontWeight: FontWeight.bold,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero, // Crucial for centering text
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onOtpChanged(index, value),
        showCursor: false, // Hide cursor for cleaner "Pin Pad" look
      ),
    );
  }
}

