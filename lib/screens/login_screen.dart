import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_icons.dart';
import '../blocs/bloc_exports.dart';
import '../screens/register_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../services/user_service.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';
import '../widgets/neumorphic/neumorphic_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const String id = 'login_screen';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        
        await UserService.clearGuestStatus();
        
        if (mounted) {
          context.read<UserProfileBloc>().add(const LoadUserProfile());
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? context.read<LanguageBloc>().translate('login_failed')),
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

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _googleSignIn.initialize();
      final Future<GoogleSignInAuthenticationEvent> eventFuture =
          _googleSignIn.authenticationEvents.first;
      await _googleSignIn.authenticate();
      final GoogleSignInAuthenticationEvent event = await eventFuture;
      if (event is! GoogleSignInAuthenticationEventSignIn) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final String? idToken = event.user.authentication.idToken;
      if (idToken == null) {
        throw Exception('Google Sign-In returned null idToken');
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);

      await _auth.signInWithCredential(credential);
      await UserService.clearGuestStatus();

      if (mounted) {
        context.read<UserProfileBloc>().add(const LoadUserProfile());
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.read<LanguageBloc>().translate('google_login_failed')}: $e'),
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

  Future<void> _continueAsGuest() async {
    await UserService.setGuestUser(true);
    if (mounted) {
      context.read<UserProfileBloc>().add(const LoadUserProfile());
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
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
          backgroundColor: NeumorphicColors.getBackground(context),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      
                      // Neumorphic Card
                      NeumorphicContainer(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 30,
                        child: Column(
                          children: [
                            Text(
                              languageBloc.translate('welcome_back'),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: NeumorphicColors.getText(context),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                ? 'Devam etmek için giriş yapın'
                                : 'Sign in to continue',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: NeumorphicColors.getText(context).withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email Field (Debossed)
                                  NeumorphicTextField(
                                    controller: _emailController,
                                    hintText: languageBloc.translate('email'),
                                    prefixIcon: Icon(AppIcons.email, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
                                    keyboardType: TextInputType.emailAddress,
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Password Field (Debossed)
                                  NeumorphicTextField(
                                    controller: _passwordController,
                                    hintText: languageBloc.translate('password'),
                                    prefixIcon: Icon(AppIcons.lock, color: NeumorphicColors.getText(context).withValues(alpha: 0.5)),
                                    obscureText: !_isPasswordVisible,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordVisible ? AppIcons.visibilityOff : AppIcons.visibility,
                                        color: NeumorphicColors.getText(context).withValues(alpha: 0.5),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible = !_isPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  if (_isLoading)
                                    const CircularProgressIndicator()
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        // Login Button
                                        NeumorphicButton(
                                          onPressed: _login,
                                          color: NeumorphicColors.accentBlue,
                                          child: Center(
                                            child: Text(
                                              languageBloc.translate('login'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        
                                        // Google Sign In
                                        NeumorphicButton(
                                          onPressed: _signInWithGoogle,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/google_logo.png',
                                                height: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                languageBloc.translate('sign_in_with_google'),
                                                style: TextStyle(
                                                  color: NeumorphicColors.getText(context),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
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
                      
                      const SizedBox(height: 32),
                      
                      // Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(ForgotPasswordScreen.id),
                            child: Text(
                              languageBloc.translate('forgot_password'),
                              style: TextStyle(color: NeumorphicColors.getText(context)),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pushNamed(RegisterScreen.id),
                            child: Text(
                              languageBloc.translate('register'),
                              style: TextStyle(
                                color: NeumorphicColors.accentBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      TextButton.icon(
                        onPressed: _continueAsGuest,
                        icon: Icon(AppIcons.person, color: NeumorphicColors.getText(context).withValues(alpha: 0.7)),
                        label: Text(
                          languageBloc.translate('guest_login'),
                          style: TextStyle(color: NeumorphicColors.getText(context).withValues(alpha: 0.7)),
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
    );
  }
}
