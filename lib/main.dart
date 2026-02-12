import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '/app_router.dart';
import 'utils/app_theme.dart';
import 'viewmodels/auth_viewmodel.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication ViewModel
        ChangeNotifierProvider(
          create: (_) => AuthViewModel()..autoLogin(),
        ),

        // Add other providers here as needed
        // Example:
        // ChangeNotifierProvider(create: (_) => CourseViewModel()),
        // ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, child) {
          return MaterialApp.router(
            title: 'Na9raw',
            debugShowCheckedModeBanner: false,

            // Responsive Theme configuration
            theme: AppTheme.light,
            //darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system, // Automatically switch based on system

            // Optional: Use builder to apply responsive theme dynamically
            builder: (context, child) {
              // Get responsive theme based on screen size
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final responsiveTheme = AppTheme.getTheme(context, isDark);

              return Theme(
                data: responsiveTheme,
                child: child ?? const SizedBox.shrink(),
              );
            },

            // Router configuration
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

// Optional: Add a splash screen while checking auth state
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/na9raw-landscape.png',
              width: MediaQuery.of(context).size.width * 0.5, // Responsive width
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}