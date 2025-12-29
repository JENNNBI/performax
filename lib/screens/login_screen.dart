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

import 'package:provider/provider.dart';
import '../services/user_provider.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  
  const LoginScreen({super.key});

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
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('🔐 LOGIN FLOW STARTED');
        debugPrint('   Email: ${_emailController.text.trim()}');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        // 1️⃣ Clear previous session RAM state
        await Provider.of<UserProvider>(context, listen: false).clearSession();
        debugPrint('✅ Step 1: Previous session cleared');

        // 2️⃣ Authenticate with Firebase
        final credential = await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        debugPrint('✅ Step 2: Firebase authentication successful');
        
        await UserService.clearGuestStatus();
        
        if (mounted && credential.user != null) {
          final userId = credential.user!.uid;
          debugPrint('   User ID: $userId');
          
          // 3️⃣ 🎯 CRITICAL: Load user-specific data from disk
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          await userProvider.loadUserData(userId);
          debugPrint('✅ Step 3: User data loaded from disk');
          
          // 4️⃣ Load user profile from Firestore
          context.read<UserProfileBloc>().add(const LoadUserProfile());
          debugPrint('✅ Step 4: User profile bloc triggered');
          
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            debugPrint('✅ LOGIN SUCCESSFUL - Navigating to Home');
            debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ LOGIN FAILED: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? context.read<LanguageBloc>().translate('login_failed')),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ UNEXPECTED ERROR during login: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login error: $e'),
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
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('🔐 GOOGLE SIGN-IN FLOW STARTED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // 1️⃣ Clear previous session
      await Provider.of<UserProvider>(context, listen: false).clearSession();
      
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

      // 2️⃣ Authenticate with Firebase
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ Google authentication successful');
      
      await UserService.clearGuestStatus();

      if (mounted && userCredential.user != null) {
        final userId = userCredential.user!.uid;
        debugPrint('   User ID: $userId');
        
        // 3️⃣ 🎯 CRITICAL: Load user-specific data
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.loadUserData(userId);
        debugPrint('✅ User data loaded from disk');
        
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
          backgroundColor: const Color(0xFF0F172A), // Deep Blue / Dark Background
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
                        color: const Color(0xFF1E293B), // Darker Card Background
                        child: Column(
                          children: [
                            Text(
                              'Hoşgeldin', // Updated Copy
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white, // Bright White
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              languageBloc.currentLanguage == 'tr'
                                ? 'Devam etmek için giriş yapın'
                                : 'Sign in to continue',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white70, // Off-White
                              ),
                            ),
                            const SizedBox(height: 30),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // Email Field (Dark Filled Style)
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: languageBloc.translate('email'),
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                      prefixIcon: Icon(AppIcons.email, color: Colors.white.withValues(alpha: 0.5)),
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Password Field (Dark Filled Style)
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      hintText: languageBloc.translate('password'),
                                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                      prefixIcon: Icon(AppIcons.lock, color: Colors.white.withValues(alpha: 0.5)),
                                      filled: true,
                                      fillColor: Colors.black.withValues(alpha: 0.2),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible ? AppIcons.visibilityOff : AppIcons.visibility,
                                          color: Colors.white.withValues(alpha: 0.5),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  
                                  if (_isLoading)
                                    const CircularProgressIndicator(color: Colors.cyanAccent)
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
                                          color: Colors.white, // Keep Google button white/light for brand compliance or contrast
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
                                                style: const TextStyle(
                                                  color: Colors.black87,
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
