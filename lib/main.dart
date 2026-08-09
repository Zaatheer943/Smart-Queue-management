import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/services/firebase_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (gracefully handle if not configured)
  try {
    await FirebaseService.initialize();
  } catch (e) {
    // Firebase not configured - app will run in demo mode
    debugPrint('Firebase not configured: $e');
    debugPrint('App will run in demo mode without Firebase features');
  }
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
