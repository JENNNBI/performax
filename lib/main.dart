import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:firebase_core/firebase_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:performax/blocs/ogrenci_bloc/konu_anlatimli_videolar_bloc.dart';
import 'package:performax/blocs/ogrenci_bloc/ornek_yazililar_bloc.dart';
import 'package:performax/blocs/ogrenci_bloc/soru_cozum_videolari_bloc.dart';
import 'blocs/bloc_exports.dart';
import 'screens/splash_screen.dart';
import 'services/app_router.dart';
import 'services/app_theme.dart';
import 'services/localization_service.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('❌ FlutterError: ${details.exception}');
      if (details.stack != null) {
        debugPrint(details.stack.toString());
      }
    };
    ui.PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('❌ Uncaught zone error: $error');
      debugPrint(stack.toString());
      return true;
    };
    
    try {
      await dotenv.load(fileName: ".env");
      debugPrint('✅ .env file loaded successfully');
    } catch (e) {
      debugPrint('⚠️ Could not load .env file: $e');
      debugPrint('⚠️ Continuing without environment variables');
    }
    
    try {
      final dir = await getApplicationDocumentsDirectory();
      final storage = await HydratedStorage.build(
        storageDirectory: HydratedStorageDirectory(dir.path),
      );
      HydratedBloc.storage = storage;
      debugPrint('✅ HydratedStorage initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Error initializing HydratedStorage: $e');
      debugPrint('⚠️ App will continue but state persistence may not work');
    }

    try {
      await Future.wait([
        Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
        LocalizationService.initialize(),
      ]);
      debugPrint('✅ Firebase and LocalizationService initialized successfully');
    } catch (e) {
      debugPrint('⚠️ Error initializing Firebase or LocalizationService: $e');
      try {
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('✅ Firebase initialized successfully (separate)');
      } catch (firebaseError) {
        debugPrint('⚠️ Critical: Firebase initialization failed: $firebaseError');
        debugPrint('⚠️ App will still run but Firebase features won\'t work');
      }
      try {
        await LocalizationService.initialize();
        debugPrint('✅ LocalizationService initialized successfully (separate)');
      } catch (localizationError) {
        debugPrint('⚠️ Warning: LocalizationService initialization failed: $localizationError');
        debugPrint('⚠️ App will continue without localization');
      }
    }
    
    debugPrint('🚀 Starting Flutter app...');
    runApp(const MyApp());
  } catch (e, stackTrace) {
    debugPrint('❌ CRITICAL ERROR in main(): $e');
    debugPrint('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => KonuAnlatimliVideolarBloc()),
        BlocProvider(create: (context) => SoruCozumVideolariBloc()),
        BlocProvider(create: (context) => OrnekYazililarBloc()),
        BlocProvider(create: (context) => UserProfileBloc()),
        BlocProvider(create: (context) => LanguageBloc()),
        BlocProvider(create: (context) => BottomNavVisibilityBloc()),
        BlocProvider(create: (context) => TasksBloc()),
        BlocProvider(create: (context) => SwitchBloc()),
      ],
      child: MaterialApp(
        title: 'Performax',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        showPerformanceOverlay: kDebugMode,
        onGenerateRoute: AppRouter().onGenerateRoute,
        home: const SplashScreen(),
      ),
    );
  }
}
