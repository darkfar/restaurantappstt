// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'data/data.dart'; // Import semua dari file data.dart
import 'providers/providers.dart'; // Import semua dari file providers.dart
import 'ui/pages/pages.dart'; // Import pages
import 'utils/utils.dart'; // Import utils
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database for Windows/Linux
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize NotificationHelper using singleton
  final notificationHelper = NotificationHelper.instance;

  try {
    await notificationHelper.initNotifications();
    debugPrint('NotificationHelper initialized successfully');
  } catch (e) {
    debugPrint('Failed to initialize NotificationHelper: $e');
    // Continue running the app even if notification initialization fails
  }

  runApp(MyApp(
    sharedPreferences: sharedPreferences,
    notificationHelper: notificationHelper,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences sharedPreferences;
  final NotificationHelper notificationHelper;

  const MyApp({
    super.key,
    required this.sharedPreferences,
    required this.notificationHelper,
  });

  @override
  Widget build(BuildContext context) {
    final preferencesHelper = PreferencesHelper(
      sharedPreferences: Future.value(sharedPreferences),
    );

    return MultiProvider(
      providers: [
        // Restaurant Provider - no dependencies
        ChangeNotifierProvider(
          create: (context) => RestaurantProvider(),
        ),

        // Theme Provider - depends on preferences
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(
            preferencesHelper: preferencesHelper,
          ),
        ),

        // Favorite Provider - no dependencies
        ChangeNotifierProvider(
          create: (context) => FavoriteProvider(),
        ),

        // Settings Provider - depends on preferences and notifications
        ChangeNotifierProvider(
          create: (context) => SettingsProvider(
            preferencesHelper: preferencesHelper,
            notificationHelper: notificationHelper,
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          // Show loading screen while theme is being loaded
          if (themeProvider.isLoading) {
            return MaterialApp(
              title: 'Restaurant App',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading...'),
                    ],
                  ),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Restaurant App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const MainNavigation(),
          );
        },
      ),
    );
  }
}