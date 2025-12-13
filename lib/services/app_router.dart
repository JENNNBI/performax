// lib/services/app_router.dart
import 'package:flutter/material.dart';
import 'package:performax/screens/first_screen.dart';
import 'package:performax/screens/splash_screen.dart';
import 'package:performax/screens/onboarding_screen.dart';
import 'package:performax/screens/forgot_password_screen.dart';
import 'package:performax/screens/info_screen.dart';
import 'package:performax/screens/konu_anlatimli_videolar_screen.dart';
import 'package:performax/screens/login_screen.dart';
import 'package:performax/screens/ornek_yazililar_screen.dart';
import 'package:performax/screens/password_reset_confirmation_screen.dart';
import 'package:performax/screens/register_screen.dart';
import 'package:performax/screens/registration_details_screen.dart';
import 'package:performax/screens/profile_screen.dart';
import 'package:performax/screens/soru_cozum_videolari_screen.dart';
import 'package:performax/screens/home_screen.dart';
import 'package:performax/screens/settings_screen.dart';
import 'package:performax/screens/change_password_screen.dart';
import 'package:performax/screens/qr_generator_screen.dart';
import 'package:performax/screens/pdf_resources_screen.dart';
import 'package:performax/screens/biology_9th_grade_screen.dart';
import 'package:performax/screens/denemeler_screen.dart';
import 'package:performax/screens/favorites_screen.dart';
import 'package:performax/screens/favorite_questions_screen.dart';
import 'package:performax/screens/favorite_books_screen.dart';


class AppRouter {
  Route? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.id:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case OnboardingScreen.id:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case FirstScreen.id:
        return MaterialPageRoute(builder: (_) => const FirstScreen());
      case LoginScreen.id:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case RegisterScreen.id:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case RegistrationDetailsScreen.id:
        final Map<String, String>? args = settings.arguments as Map<String, String>?;
        if (args != null && args['email'] != null && args['password'] != null) {
          return MaterialPageRoute(
            builder: (_) => RegistrationDetailsScreen(
              email: args['email']!,
              password: args['password']!,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case ForgotPasswordScreen.id:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case PasswordResetConfirmationScreen.id:
        // Extract oobCode from route arguments for Firebase password reset
        final String? oobCode = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (_) => PasswordResetConfirmationScreen(oobCode: oobCode),
        );
      case InfoScreen.id:
        return MaterialPageRoute(builder: (_) => const InfoScreen());
      case '/profile':
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case HomeScreen.id:
        final int? initialTab = settings.arguments as int?;
        return MaterialPageRoute(builder: (_) => HomeScreen(initialTabIndex: initialTab));
      case '/tabs':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case KonuAnlatimliVideolarScreen.id:
        return MaterialPageRoute(builder: (_) => const KonuAnlatimliVideolarScreen());
      case OrnekYazililarScreen.id:
        return MaterialPageRoute(builder: (_) => const OrnekYazililarScreen());
      case SoruCozumVideolariScreen.id:
        return MaterialPageRoute(builder: (_) => const SoruCozumVideolariScreen());
      case SettingsScreen.id:
        final bool isGuest = settings.arguments as bool? ?? false;
        return MaterialPageRoute(builder: (_) => SettingsScreen(isGuest: isGuest));
      case ChangePasswordScreen.id:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case QRGeneratorScreen.id:
        return MaterialPageRoute(builder: (_) => const QRGeneratorScreen());
      case PDFResourcesScreen.id:
        return MaterialPageRoute(builder: (_) => const PDFResourcesScreen());
      case Biology9thGradeScreen.id:
        return MaterialPageRoute(builder: (_) => const Biology9thGradeScreen());
      case DenemelerScreen.id:
        return MaterialPageRoute(
          builder: (_) => const DenemelerScreen(),
          settings: settings,
        );
      case FavoritesScreen.id:
        return MaterialPageRoute(
          builder: (_) => const FavoritesScreen(),
        );
      case FavoriteQuestionsScreen.id:
        return MaterialPageRoute(
          builder: (_) => const FavoriteQuestionsScreen(),
        );
      case FavoriteBooksScreen.id:
        return MaterialPageRoute(
          builder: (_) => const FavoriteBooksScreen(),
        );
      default:
        return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Center(child: Text('Sayfa bulunamadı'))));
    }
  }
}