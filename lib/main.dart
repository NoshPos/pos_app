import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos_app/features/onboarding/view/pages/login_page.dart';
import 'package:pos_app/features/dashboard/view/pages/dashboard_page.dart';
import 'package:pos_app/core/providers/theme_provider.dart';
import 'package:pos_app/core/providers/local_storage_provider.dart';
import 'package:pos_app/core/config/supabase_config.dart';
import 'package:pos_app/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize SharedPreferences for local storage
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize Firebase (for Phone Auth) - handle if already initialized
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase already initialized, ignore
  }

  // Initialize Supabase (for everything else)
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        // Override the SharedPreferences provider with the actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeModeNotifierProvider);

    return MaterialApp(
      title: 'POS APP',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

/// Wrapper widget that checks authentication state and shows appropriate screen
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  bool _isRoleValid = false;
  String? _roleError;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final supabase = Supabase.instance.client;
      final localStorageService = ref.read(localStorageServiceProvider);

      // Check if there's a valid Supabase session
      final session = supabase.auth.currentSession;

      if (session != null) {
        // User has a valid session, save it locally
        await localStorageService.saveAuthSession(
          userId: session.user.id,
          email: session.user.email,
          accessToken: session.accessToken,
          refreshToken: session.refreshToken ?? '',
        );

        // Validate user role for app access
        final roleValid = await _validateUserRole();

        setState(() {
          _isAuthenticated = true;
          _isRoleValid = roleValid;
          _isLoading = false;
        });
      } else {
        // No Supabase session, check if we have stored tokens to restore
        final storedRefreshToken = localStorageService.refreshToken;

        if (storedRefreshToken != null && storedRefreshToken.isNotEmpty) {
          // Try to restore the session using the refresh token
          try {
            final response = await supabase.auth.setSession(storedRefreshToken);
            if (response.session != null) {
              // Session restored successfully, update stored tokens
              await localStorageService.saveAuthSession(
                userId: response.session!.user.id,
                email: response.session!.user.email,
                accessToken: response.session!.accessToken,
                refreshToken: response.session!.refreshToken ?? '',
              );

              // Validate user role for app access
              final roleValid = await _validateUserRole();

              setState(() {
                _isAuthenticated = true;
                _isRoleValid = roleValid;
                _isLoading = false;
              });
              return;
            }
          } catch (e) {
            // Failed to restore session, clear local storage
            await localStorageService.clearAuthSession();
          }
        }

        setState(() {
          _isAuthenticated = false;
          _isRoleValid = false;
          _isLoading = false;
        });
      }

      // Listen to auth state changes
      supabase.auth.onAuthStateChange.listen((data) async {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          await localStorageService.saveAuthSession(
            userId: session.user.id,
            email: session.user.email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? '',
          );

          // Validate role on sign in
          final roleValid = await _validateUserRole();

          if (mounted) {
            setState(() {
              _isAuthenticated = true;
              _isRoleValid = roleValid;
            });
          }
        } else if (event == AuthChangeEvent.signedOut) {
          await localStorageService.clearAuthSession();
          if (mounted) {
            setState(() {
              _isAuthenticated = false;
              _isRoleValid = false;
              _roleError = null;
            });
          }
        } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
          // Update stored tokens when they're refreshed
          await localStorageService.saveAuthSession(
            userId: session.user.id,
            email: session.user.email,
            accessToken: session.accessToken,
            refreshToken: session.refreshToken ?? '',
          );
        }
      });
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isRoleValid = false;
        _isLoading = false;
      });
    }
  }

  /// Validate that the user has owner/admin role for app access
  Future<bool> _validateUserRole() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return false;

      // Try to get existing profile
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      // If no profile exists, create one
      if (response == null) {
        // Create a new profile for the user
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': user.email ?? '',
          'full_name':
              user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
          'role':
              'owner', // New users get owner role by default (can be changed in DB)
        });

        // After creating, the user is an owner
        return true;
      }

      final role = response['role'] as String?;
      final isOwnerOrAdmin = role == 'owner' || role == 'admin';

      if (!isOwnerOrAdmin) {
        setState(() {
          _roleError =
              'Access Denied: This app is only for store owners and administrators.';
        });
        // Sign out the user
        await supabase.auth.signOut();
      }

      return isOwnerOrAdmin;
    } catch (e) {
      debugPrint('Error validating user role: $e');
      setState(() {
        _roleError = 'Failed to verify access. Please try again. Error: $e';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show error page if authenticated but role is invalid
    if (_isAuthenticated && !_isRoleValid && _roleError != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _roleError!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please use the web POS for billing operations.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      setState(() {
                        _isAuthenticated = false;
                        _isRoleValid = false;
                        _roleError = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _isAuthenticated && _isRoleValid
        ? const DashboardPage()
        : const LoginPage();
  }
}
