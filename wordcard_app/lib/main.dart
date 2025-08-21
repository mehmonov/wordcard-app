import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:WordCard/screens/login_screen.dart';
import 'package:WordCard/screens/home_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final apiKey = dotenv.env['API_KEY'] ?? '';
  final baseUrl = dotenv.env['BASE_URL'] ?? '';

  await Supabase.initialize(
    url: apiKey, 
    anonKey: baseUrl, 
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
  ],
  redirect: (context, state) {
    final session = supabase.auth.currentSession;
    final onLoginPage = state.matchedLocation == '/login';
  
    if (session == null) {
      return onLoginPage ? null : '/login';
    }

    if (onLoginPage) {
      return '/';
    }

    return null;
  },
  refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false, 
      title: 'WordCard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00796B), 
          brightness: Brightness.dark,
          primary: const Color(0xFF26A69A), 
          secondary: const Color(0xFF80CBC4), 
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

// Stream to notify GoRouter of auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    stream.asBroadcastStream().listen((_) => notifyListeners());
  }
}
