import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'core/storage/isar_service.dart';
import 'core/storage/prefs_service.dart';
import 'core/network/supabase_client.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification plugin
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // Initialize dependency injection
  await di.init(flutterLocalNotificationsPlugin);

  // Ensure DB and Prefs are initialized before starting app
  await di.sl<DatabaseService>().init();
  await di.sl<PrefsService>().init();
  await SupabaseClientService.initialize();

  // Sign in anonymously to enable realtime signaling and database access
  try {
    await SupabaseClientService().signInAnonymously();
  } catch (e) {
    debugPrint('Supabase anonymous sign-in failed: $e');
  }

  runApp(const CampusOsApp());
}
