import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:performax/screens/login_screen.dart';

class PasswordResetConfirmationScreen extends StatefulWidget {
  const PasswordResetConfirmationScreen({
    super.key,
    this.oobCode,
  });
  
  static const id = 'password_reset_confirmation_screen';
  final String? oobCode; // Out-of-band code from Firebase

  @override
  State<PasswordResetConfirmationScreen> createState() => _PasswordResetConfirmationScreenState();
}

class _PasswordResetConfirmationScreenState extends State<PasswordResetConfirmationScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _passwordResetComplete = false;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _verifyResetCode();
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyResetCode() async {
    if (widget.oobCode == null) {
      _showErrorAndNavigateBack('Geçersiz şifre sıfırlama bağlantısı.');
      return;
    }

    try {
      // Verify the password reset code and get the email
      final email = await _auth.verifyPasswordResetCode(widget.oobCode!);
      setState(() {
        _userEmail = email;
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'expired-action-code':
          errorMessage = 'Şifre sıfırlama bağlantısı süresi dolmuş. Lütfen yeni bir bağlantı isteyin.';
          break;
        case 'invalid-action-code':
          errorMessage = 'Geçersiz şifre sıfırlama bağlantısı.';
          break;
        case 'user-disabled':
          errorMessage = 'Bu kullanıcı hesabı devre dışı bırakılmış.';
          break;
        case 'user-not-found':
          errorMessage = 'Kullanıcı bulunamadı.';
          break;
        default:
          errorMessage = 'Bağlantı doğrulanamadı: ${e.message}';
      }
      _showErrorAndNavigateBack(errorMessage);
    } catch (e) {
      _showErrorAndNavigateBack('Beklenmeyen bir hata oluştu: $e');
    }
  }

  void _showErrorAndNavigateBack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.of(context).pushReplacementNamed(LoginScreen.id);
    });
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _auth.confirmPasswordReset(
          code: widget.oobCode!,
          newPassword: _newPasswordController.text,
        );

        if (mounted) {
          setState(() {
            _passwordResetComplete = true;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Şifreniz başarıyla sıfırlandı!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );

          // Navigate to login after a delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(LoginScreen.id);
            }
          });
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'expired-action-code':
            errorMessage = 'Şifre sıfırlama bağlantısı süresi dolmuş. Lütfen yeni bir bağlantı isteyin.';
            break;
          case 'invalid-action-code':
            errorMessage = 'Geçersiz şifre sıfırlama bağlantısı.';
            break;
          case 'weak-password':
            errorMessage = 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
            break;
          default:
            errorMessage = 'Şifre sıfırlanamadı: ${e.message}';
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Beklenmeyen bir hata oluştu: $e'),
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
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Yeni şifre gereklidir';
    }
    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    if (value.length > 128) {
      return 'Şifre en fazla 128 karakter olabilir';
    }
    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Şifre en az bir harf ve bir rakam içermelidir';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }
    if (value != _newPasswordController.text) {
      return 'Şifreler eşleşmiyor';
    }
    return null;
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
    required IconData prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: onToggleVisibility,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        obscureText: !isVisible,
        validator: validator,
        enabled: !_isLoading && !_passwordResetComplete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_userEmail == null && !_passwordResetComplete) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.primaryColor),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yeni Şifre Belirle'),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    _passwordResetComplete 
                        ? Icons.check_circle_outline
                        : Icons.lock_reset,
                    size: 80,
                    color: _passwordResetComplete 
                        ? Colors.green 
                        : theme.primaryColor,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _passwordResetComplete 
                        ? 'Şifre Başarıyla Sıfırlandı!'
                        : 'Yeni Şifrenizi Belirleyin',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _passwordResetComplete 
                          ? Colors.green 
                          : theme.primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_userEmail != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.email_outlined,
                            color: theme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _userEmail!,
                              style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    _passwordResetComplete
                        ? 'Artık yeni şifrenizle giriş yapabilirsiniz. Giriş sayfasına yönlendiriliyorsunuz...'
                        : 'Yeni şifrenizi girin ve tekrar edin. Şifre en az 6 karakter olmalı ve bir harf ile bir rakam içermelidir.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_passwordResetComplete) ...[
                    _buildPasswordField(
                      controller: _newPasswordController,
                      label: 'Yeni Şifre',
                      isVisible: _isNewPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                      validator: _validateNewPassword,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildPasswordField(
                      controller: _confirmPasswordController,
                      label: 'Yeni Şifre Tekrar',
                      isVisible: _isConfirmPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                      validator: _validateConfirmPassword,
                      prefixIcon: Icons.lock_outline,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isLoading ? null : _resetPassword,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save),
                                SizedBox(width: 8),
                                Text(
                                  'Şifreyi Sıfırla',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacementNamed(LoginScreen.id),
                      child: const Text('Giriş Sayfasına Geri Dön'),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.thumb_up,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'İşlem Tamamlandı',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 