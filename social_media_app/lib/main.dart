import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:social_media_app/screens/auth_screen.dart';
import 'package:social_media_app/screens/create_post_screen.dart';
import 'package:social_media_app/screens/create_profile_screen.dart';
import 'package:social_media_app/screens/create_story_screen.dart';
import 'package:social_media_app/screens/explore_screen.dart';
import 'package:social_media_app/screens/feed_screen.dart';
import 'package:social_media_app/screens/profile_screen.dart';
import 'package:social_media_app/screens/splash_screen.dart';
import 'package:social_media_app/services/firebase_service.dart';
import 'package:social_media_app/theme/app_theme.dart';
import 'package:social_media_app/widgets/bottom_nav.dart';

void main() async {
  // Ensure that all Flutter framework bindings are initialized before doing anything else.
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize all our Firebase services.
  await FirebaseService.initialize();
  // Set the system UI to be clean and immersive.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const GameFeedApp());
}

class GameFeedApp extends StatelessWidget {
  const GameFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameFeed',
      debugShowCheckedModeBanner: false,
      // The global theme for the entire application.
      theme: AppTheme.dark.copyWith(
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          labelStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIconColor: AppTheme.textSecondary,
        ),
      ),
      // The app always starts with the SplashScreen.
      home: const SplashScreen(), 
    );
  }
}

// This special widget acts as the main "gatekeeper" or router for the app.
// After the splash screen, the app navigates here. This widget's only job is to
// listen to the user's authentication state and show the correct screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // A StreamBuilder listens to a continuous stream of data and rebuilds the UI
    // whenever new data is received.
    return StreamBuilder<User?>(
      // We are listening to the `userChanges()` stream from FirebaseAuth.
      // This stream is "smarter" than `authStateChanges()` because it emits a new event
      // not only on login/logout, but also when the current user's profile data changes
      // (like when they update their username).
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        // While waiting for the first authentication event, show a loading spinner.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: AppTheme.bg, body: Center(child: CircularProgressIndicator()));
        }

        // If the snapshot has data, it means a user is logged in.
        if (snapshot.hasData) {
          final user = snapshot.data!;
          // CRITICAL CHECK: We check if the user has set a display name yet.
          // If they haven't, it means they are a new user who has just signed up.
          if (user.displayName == null || user.displayName!.isEmpty) {
            // We force them to the CreateProfileScreen to set their name.
            return const CreateProfileScreen();
          }
          // If they do have a name, they are an existing user. Show the main app.
          return const MainShell();
        }

        // If the snapshot has no data, it means no user is logged in. Show the AuthScreen.
        return const AuthScreen();
      },
    );
  }
}

// This is the main UI of the app, containing the bottom navigation bar and the screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // The list of screens accessible from the bottom navigation bar.
  final List<Widget> _screens = [
    const FeedScreen(),
    const ExploreScreen(),
    const ProfileScreen(),
  ];

  // This function is called when a navigation bar item is tapped.
  void _onTap(int index) {
    // The middle button (index 2) is a special "add" button.
    if (index == 2) {
      _showAddSheet();
      return;
    }
    // We remap the index to account for the placeholder in the middle.
    int screenIndex = index > 2 ? index - 1 : index;
    setState(() {
      _currentIndex = screenIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This logic ensures the correct nav bar item is highlighted.
    int navIndex = _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      // IndexedStack is an efficient way to show only one screen from a list at a time.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: navIndex,
        onTap: _onTap,
      ),
    );
  }

  // This function shows the bottom sheet for creating a new post or story.
  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.post_add, color: AppTheme.accent)),
              title: const Text('Post', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostScreen()));
              },
            ),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.auto_stories, color: AppTheme.accent)),
              title: const Text('Story', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateStoryScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }
}
