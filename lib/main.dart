import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/execution_provider.dart';
import 'providers/recipe_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'services/hive_service.dart';
import 'services/notification_service.dart';
import 'services/timer_service.dart';
import 'widgets/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive (local storage)
  await HiveService.init();

  // Initialize local notifications
  await NotificationService().init();

  runApp(const CookFlowApp());
}

class CookFlowApp extends StatelessWidget {
  const CookFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeProvider()),
        ChangeNotifierProvider(create: (_) => ExecutionProvider()),
        // TimerService is a singleton ChangeNotifier
        ChangeNotifierProvider(create: (_) => TimerService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Set system UI overlay style based on theme
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: themeProvider.isDarkMode
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );

          return MaterialApp(
            title: 'CookFlow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
