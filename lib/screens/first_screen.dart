import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:performax/screens/login_screen.dart';
import '../theme/neumorphic_colors.dart';
import '../widgets/neumorphic/neumorphic_container.dart';
import '../widgets/neumorphic/neumorphic_button.dart';

class FirstScreen extends StatefulWidget {
  const FirstScreen({super.key});
  static const String id = 'first_screen';

  @override
  State<FirstScreen> createState() => _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _navigateToLogin(BuildContext context) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_seen_first_screen', true);
    });
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.id);
    }
  }

  Future<void> _navigateToTeacher(BuildContext context) async {
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('has_seen_first_screen', true);
      prefs.setBool('is_teacher_mode', true);
    });
    
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, LoginScreen.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = NeumorphicColors.getBackground(context);
    final textColor = NeumorphicColors.getText(context);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Container
                  NeumorphicContainer(
                    padding: const EdgeInsets.all(40),
                    borderRadius: 40,
                    depth: 10,
                    child: Column(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          size: 64,
                          color: NeumorphicColors.accentBlue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Performax',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Hoş Geldiniz',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Student Button
                  NeumorphicButton(
                    onPressed: () => _navigateToLogin(context),
                    color: NeumorphicColors.accentBlue,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.school_rounded, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Öğrenci Olarak Devam Et',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Teacher Button
                  NeumorphicButton(
                    onPressed: () => _navigateToTeacher(context),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_outline_rounded, color: textColor),
                        const SizedBox(width: 12),
                        Text(
                          'Öğretmen Olarak Devam Et',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
