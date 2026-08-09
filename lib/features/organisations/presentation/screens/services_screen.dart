import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/organisations/presentation/providers/organisation_provider.dart';
import 'package:queuewise/features/queues/presentation/providers/queue_provider.dart';
import 'package:queuewise/shared/models/service_model.dart';

/// Services selection screen
class ServicesScreen extends ConsumerWidget {
  final String organisationId;

  const ServicesScreen({super.key, required this.organisationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(servicesProviderFamily(organisationId));
    final services = servicesState.services;
    final isLoading = servicesState.isLoading;
    final errorMessage = servicesState.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go(AppRouter.organisations);
          },
        ),
      ),
      body: _buildContent(services, isLoading, errorMessage, ref),
    );
  }

  Widget _buildContent(
    List<ServiceModel> services,
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
                ref
                    .read(servicesProviderFamily(organisationId).notifier)
                    .loadServices(organisationId);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.miscellaneous_services_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No services available',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return _ServiceCard(
          service: service,
          onTap: () async {
            final user = ref.read(currentUserProvider);
            if (user == null) return;

            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Join Queue'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Service: ${service.name}'),
                    const SizedBox(height: 8),
                    Text('Organisation ID: $organisationId'),
                    const SizedBox(height: 8),
                    Text('Estimated duration: ~${service.averageServiceDuration} min'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Join Queue'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              // Join the queue
              await ref.read(queueProviderFamily(user.uid).notifier).joinQueue(
                    organisationId: organisationId,
                    serviceId: service.id,
                    userId: user.uid,
                  );

              // Navigate to active queue screen
              if (context.mounted) {
                context.go(AppRouter.queue);
              }
            }
          },
        );
      },
    );
  }
}

/// Service card widget
class _ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.service,
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.miscellaneous_services,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        if (service.description.isNotEmpty)
                          Text(
                            service.description,
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
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '~${service.averageServiceDuration} min per person',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.add),
                    label: const Text('Join Queue'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
