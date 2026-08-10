import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/organisations/presentation/providers/organisation_provider.dart';
import 'package:queuewise/features/queues/presentation/providers/queue_provider.dart';
import 'package:queuewise/shared/models/organisation_model.dart';

/// Admin dashboard screen
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organisationsState = ref.watch(organisationsProvider);
    final organisations = organisationsState.organisations;
    final isLoading = organisationsState.isLoading;
    final errorMessage = organisationsState.errorMessage;

    // Load statistics for the first organisation
    final stats = organisations.isNotEmpty 
        ? ref.watch(_statisticsProvider(organisations.first.id)).value
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // Sign out and navigate to landing
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              context.go(AppRouter.landing);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading
                ? null
                : () {
                    ref.read(organisationsProvider.notifier).loadOrganisations();
                  },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Statistics Cards
          if (stats != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _StatisticsCards(stats: stats),
              ),
            ),
          // Admin Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRouter.createAdmin);
                    },
                    icon: const Icon(Icons.person_add),
                    label: const Text('Create Admin Account'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push(AppRouter.createOrganisation);
                    },
                    icon: const Icon(Icons.business),
                    label: const Text('Add Organisation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider
          const SliverToBoxAdapter(child: Divider()),
          // Organisations List
          _buildContent(organisations, isLoading, errorMessage, ref),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<OrganisationModel> organisations,
    bool isLoading,
    String? errorMessage,
    WidgetRef ref,
  ) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: TextStyle(color: Colors.red[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(organisationsProvider.notifier).loadOrganisations();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (organisations.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings_outlined,
                  size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No organisations available',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final organisation = organisations[index];
          return _OrganisationAdminCard(
            organisation: organisation,
            onEdit: () {
              context.push(AppRouter.editOrganisation, extra: {
                'organisationId': organisation.id,
                'organisation': organisation,
              });
            },
            onManageServices: () {
              context.push(AppRouter.manageServices, extra: {
                'organisationId': organisation.id,
                'organisationName': organisation.name,
              });
            },
            onAddService: () {
              context.push(AppRouter.createService, extra: {
                'organisationId': organisation.id,
                'organisationName': organisation.name,
              });
            },
          );
        },
        childCount: organisations.length,
      ),
    );
  }
}

/// Statistics cards widget
class _StatisticsCards extends StatelessWidget {
  final Map<String, dynamic> stats;

  const _StatisticsCards({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Queue Statistics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Waiting',
                  value: '${stats['totalWaiting'] ?? 0}',
                  icon: Icons.people,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Currently Serving',
                  value: '${stats['currentlyServing'] ?? 0}',
                  icon: Icons.support_agent,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Completed Today',
                  value: '${stats['completedToday'] ?? 0}',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  title: 'Active Queues',
                  value: '${stats['totalQueues'] ?? 0}',
                  icon: Icons.queue,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Individual statistics card
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Statistics provider
final _statisticsProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, organisationId) async {
    final queueNotifier = ref.read(queueProviderFamily('stats').notifier);
    return await queueNotifier.getQueueStatistics(organisationId);
  },
);

/// Organisation admin card
class _OrganisationAdminCard extends StatelessWidget {
  final OrganisationModel organisation;
  final VoidCallback onEdit;
  final VoidCallback onManageServices;
  final VoidCallback onAddService;

  const _OrganisationAdminCard({
    required this.organisation,
    required this.onEdit,
    required this.onManageServices,
    required this.onAddService,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        organisation.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (organisation.description.isNotEmpty)
                        Text(
                          organisation.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.business_outlined,
                    size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    organisation.address,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.phone_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  organisation.phone,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onManageServices,
                    icon: const Icon(Icons.list, size: 16),
                    label: const Text('Services'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAddService,
                    icon: const Icon(Icons.add_circle_outline, size: 16),
                    label: const Text('Add Service'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.green,
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
