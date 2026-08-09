import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:queuewise/features/organisations/presentation/providers/organisation_provider.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
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
      body: _buildContent(organisations, isLoading, errorMessage, ref),
    );
  }

  Widget _buildContent(
    List<OrganisationModel> organisations,
    bool isLoading,
    String? errorMessage,
    WidgetRef ref,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
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
      );
    }

    if (organisations.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: organisations.length,
      itemBuilder: (context, index) {
        final organisation = organisations[index];
        return _OrganisationAdminCard(
          organisation: organisation,
          onTap: () {
            // Navigate to organisation admin view
            // For now, just show a message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Managing: ${organisation.name}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}

/// Organisation admin card
class _OrganisationAdminCard extends StatelessWidget {
  final OrganisationModel organisation;
  final VoidCallback onTap;

  const _OrganisationAdminCard({
    required this.organisation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
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
            ],
          ),
        ),
      ),
    );
  }
}
