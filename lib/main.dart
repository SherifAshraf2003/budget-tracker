import 'package:expense_tracker/screens/auth/auth_wrapper.dart';
import 'package:expense_tracker/screens/auth/login_screen.dart';
import 'package:expense_tracker/screens/auth/signup_screen.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/categories_screen.dart';
import 'package:expense_tracker/screens/expenses_screen.dart';
import 'package:expense_tracker/screens/add_expense_screen.dart';
import 'package:expense_tracker/screens/reports_screen.dart';
import 'package:expense_tracker/screens/ai_insights_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables with error handling
  try {
    print('DEBUG: Attempting to load .env file...');
    await dotenv.load(fileName: ".env");
    print('DEBUG: .env file loaded successfully');
    print('DEBUG: Available environment variables: ${dotenv.env.keys.toList()}');
    final apiKey = dotenv.env['OPENROUTER_API_KEY'];
    print('DEBUG: OPENROUTER_API_KEY in main: ${apiKey != null ? "Found (${apiKey.length} chars)" : "Not found"}');
  } catch (e) {
    print('Warning: Could not load .env file: $e');
    print('The app will still work but AI insights may not be available.');
    print('Please ensure you have a .env file with OPENROUTER_API_KEY=your_key_here');
  }
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => HomeScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/expenses': (context) => const ExpensesScreen(),
        '/add-expense': (context) => const AddExpenseScreen(),
        '/reports': (context) => const ReportsScreen(),
        '/ai-insights': (context) => const AIInsightsScreen(),
      },
    );
  }
}
