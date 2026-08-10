import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/authentication/presentation/screens/landing_screen.dart';
import 'package:queuewise/features/authentication/presentation/screens/login_screen.dart';
import 'package:queuewise/features/authentication/presentation/screens/register_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/create_admin_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/create_organisation_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/create_service_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/edit_organisation_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/edit_service_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/manage_services_screen.dart';
import 'package:queuewise/features/admin/presentation/screens/view_queue_screen.dart';
import 'package:queuewise/features/organisations/presentation/screens/organisations_screen.dart';
import 'package:queuewise/features/organisations/presentation/screens/services_screen.dart';
import 'package:queuewise/features/queues/presentation/screens/active_queue_screen.dart';
import 'package:queuewise/features/staff/presentation/screens/staff_queue_screen.dart';

/// Application router configuration with authentication guards
class AppRouter {
  AppRouter._();

  // Route paths
  static const String landing = '/';
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
  static const String createAdmin = '/admin/create-admin';
  static const String createOrganisation = '/admin/create-organisation';
  static const String createService = '/admin/create-service';
  static const String editOrganisation = '/admin/edit-organisation';
  static const String editService = '/admin/edit-service';
  static const String manageServices = '/admin/manage-services';
  static const String viewQueue = '/admin/view-queue';

  // Staff routes
  static const String staffDashboard = '/staff';
  static const String staffQueue = '/staff/queue';

  /// Create router with authentication guards
  static GoRouter createRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: landing,
      redirect: (context, state) {
        final isAuthenticated = ref.read(isAuthenticatedProvider);
        final isAuthRoute = state.matchedLocation == login ||
                           state.matchedLocation == register;
        final isLandingRoute = state.matchedLocation == landing;
        
        // Redirect to landing if not authenticated and not on auth/landing route
        if (!isAuthenticated && !isAuthRoute && !isLandingRoute) {
          return landing;
        }
        
        // Redirect to landing if authenticated and on auth route
        if (isAuthenticated && isAuthRoute) {
          return landing;
        }
        
        // Redirect to appropriate screen if authenticated and on landing
        if (isAuthenticated && isLandingRoute) {
          final isAdmin = ref.read(isAdminProvider);
          final user = ref.read(currentUserProvider);
          final isStaff = user?.role == AppConstants.roleStaff;
          
          if (isAdmin) return adminDashboard;
          if (isStaff) return staffDashboard;
          return organisations;
        }
        
        return null;
      },
      routes: [
        // Landing route
        GoRoute(
          path: landing,
          builder: (context, state) => const LandingScreen(),
        ),
        
        // Login route
        GoRoute(
          path: login,
          builder: (context, state) {
            final selectedRole = state.extra as String?;
            return LoginScreen(selectedRole: selectedRole);
          },
        ),
        
        // Register route
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
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
        
        // Create admin route (protected)
        GoRoute(
          path: createAdmin,
          builder: (context, state) => const CreateAdminScreen(),
        ),
        
        // Create organisation route (protected)
        GoRoute(
          path: createOrganisation,
          builder: (context, state) => const CreateOrganisationScreen(),
        ),
        
        // Create service route (protected)
        GoRoute(
          path: createService,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return CreateServiceScreen(
              organisationId: extra?['organisationId'] ?? '',
              organisationName: extra?['organisationName'] ?? '',
            );
          },
        ),
        
        // Edit organisation route (protected)
        GoRoute(
          path: editOrganisation,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return EditOrganisationScreen(
              organisationId: extra?['organisationId'] ?? '',
              organisation: extra?['organisation'],
            );
          },
        ),
        
        // Edit service route (protected)
        GoRoute(
          path: editService,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return EditServiceScreen(
              organisationId: extra?['organisationId'] ?? '',
              serviceId: extra?['serviceId'] ?? '',
              organisationName: extra?['organisationName'] ?? '',
              serviceData: extra?['serviceData'] ?? {},
            );
          },
        ),
        
        // Manage services route (protected)
        GoRoute(
          path: manageServices,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ManageServicesScreen(
              organisationId: extra?['organisationId'] ?? '',
              organisationName: extra?['organisationName'] ?? '',
            );
          },
        ),
        
        // View queue route (protected)
        GoRoute(
          path: viewQueue,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ViewQueueScreen(
              organisationId: extra?['organisationId'] ?? '',
              organisationName: extra?['organisationName'] ?? '',
              serviceId: extra?['serviceId'] ?? '',
              serviceName: extra?['serviceName'] ?? '',
            );
          },
        ),

        // Staff dashboard route (protected)
        GoRoute(
          path: staffDashboard,
          builder: (context, state) => const _PlaceholderScreen('Staff Dashboard'),
        ),

        // Staff queue route (protected)
        GoRoute(
          path: staffQueue,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return StaffQueueScreen(
              organisationId: extra?['organisationId'] ?? '',
              organisationName: extra?['organisationName'] ?? '',
              serviceId: extra?['serviceId'] ?? '',
              serviceName: extra?['serviceName'] ?? '',
            );
          },
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isAdmin ? 'Admin Account' : 'Customer Account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              if (isAdmin) ...[
                // Admin Options
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRouter.adminDashboard);
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Admin Dashboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRouter.organisations);
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Browse Organisations'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ] else ...[
                // Customer Options
                ElevatedButton.icon(
                  onPressed: () {
                    context.go(AppRouter.organisations);
                  },
                  icon: const Icon(Icons.business),
                  label: const Text('Browse Organisations'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    context.go(AppRouter.history);
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('View Queue History'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ],
          ),
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
