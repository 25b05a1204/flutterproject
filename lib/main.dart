import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/role_selection_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ask_doubt_screen.dart';
import 'screens/matching_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notification_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const StudyBuddyApp());
}

class StudyBuddyApp extends StatelessWidget {
  const StudyBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Study Buddy',

      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFFFF8F5),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F6FA),
          foregroundColor: Color(0xFF181A2A),
          elevation: 0,
        ),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF635BFF),
        ),
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const LoginPage(),

        '/login': (context) => const LoginPage(),

        '/register': (context) => const RegisterPage(),

        '/role-selection': (context) =>
            const RoleSelectionScreen(),

        '/home': (context) => const HomeScreen(),

        '/ask-doubt': (context) =>
            const AskDoubtScreen(),

        '/matching': (context) =>
            const MatchingScreen(),

        '/leaderboard': (context) =>
            const LeaderboardScreen(),

        '/profile': (context) =>
            const ProfileScreen(),

        '/notifications': (context) =>
            const NotificationScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == '/chat') {
          final arguments = settings.arguments;

          String? requestId;

          if (arguments is String) {
            requestId = arguments;
          } else if (arguments is Map) {
            requestId = arguments['requestId']?.toString();
          }

          if (requestId == null || requestId.isEmpty) {
            return MaterialPageRoute(
              builder: (context) => const Scaffold(
                body: Center(
                  child: Text(
                    'Chat request ID is missing.',
                  ),
                ),
              ),
            );
          }

          return MaterialPageRoute(
            builder: (context) => ChatScreen(
              requestId: requestId!,
            ),
          );
        }

        return null;
      },
    );
  }
}
