import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/authentication/presentation/screens/login_screen.dart';
import 'package:queuewise/features/authentication/presentation/screens/register_screen.dart';
import 'package:queuewise/features/organisations/presentation/screens/organisations_screen.dart';
import 'package:queuewise/features/organisations/presentation/screens/services_screen.dart';
import 'package:queuewise/features/queues/presentation/screens/active_queue_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// Application router configuration with authentication guards
class AppRouter {
  AppRouter._();

  // Route paths
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String organisations = '/organisations';
  static const String organisationDetails = '/organisations/:id';
  static const String services = '/organisations/:id/services';
  static const String queue = '/queue';
  static const String history = '/history';
  static const String profile = '/profile';
  
  // Admin routes
  static const String adminDashboard = '/admin';
  static const String adminQueue = '/admin/queue';
  static const String adminAnalytics = '/admin/analytics';

  /// Create router with authentication guards
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: home,
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isAuthRoute = state.matchedLocation == login ||
                           state.matchedLocation == register;
        
        // Redirect to login if not authenticated and not on auth route
        if (!isAuthenticated && !isAuthRoute) {
          return login;
        }
        
        // Redirect to home if authenticated and on auth route
        if (isAuthenticated && isAuthRoute) {
          return home;
        }
        
        return null;
      },
      routes: [
        // Login route
        GoRoute(
          path: login,
          builder: (context, state) => const LoginScreen(),
        ),
        
        // Register route
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        
        // Home route (protected)
        GoRoute(
          path: home,
          builder: (context, state) => const _HomeScreen(),
        ),
        
        // Organisations route (protected)
        GoRoute(
          path: organisations,
          builder: (context, state) => const OrganisationsScreen(),
        ),
        
        // Services route (protected)
        GoRoute(
          path: '$organisations/:id/services',
          builder: (context, state) {
            final organisationId = state.pathParameters['id']!;
            return ServicesScreen(organisationId: organisationId);
          },
        ),
        
        // Queue route (protected)
        GoRoute(
          path: queue,
          builder: (context, state) => const ActiveQueueScreen(),
        ),
        
        // History route (protected)
        GoRoute(
          path: history,
          builder: (context, state) => const _PlaceholderScreen('History'),
        ),
        
        // Profile route (protected)
        GoRoute(
          path: profile,
          builder: (context, state) => const _PlaceholderScreen('Profile'),
        ),
        
        // Admin dashboard route (protected)
        GoRoute(
          path: adminDashboard,
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    );
  }
}

/// Temporary home screen for authenticated users
class _HomeScreen extends ConsumerWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('QueueWise'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.queue,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome, ${user?.name ?? "User"}!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin ? 'Admin Account' : 'Customer Account',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.go(AppRouter.organisations);
              },
              icon: const Icon(Icons.business),
              label: const Text('Browse Organisations'),
            ),
            const SizedBox(height: 16),
            if (isAdmin) ...[
              ElevatedButton.icon(
                onPressed: () {
                  context.go(AppRouter.adminDashboard);
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin Dashboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Temporary placeholder screen
class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.go(AppRouter.login);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$title Screen',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('Coming Soon'),
          ],
        ),
      ),
    );
  }
}
