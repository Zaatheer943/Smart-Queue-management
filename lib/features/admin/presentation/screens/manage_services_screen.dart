import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/features/organisations/presentation/providers/organisation_provider.dart';

/// Screen for admins to manage services for an organisation
class ManageServicesScreen extends ConsumerWidget {
  final String organisationId;
  final String organisationName;

  const ManageServicesScreen({
    super.key,
    required this.organisationId,
    required this.organisationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services - $organisationName'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(servicesProviderFamily(organisationId).notifier).loadServices(organisationId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Add Service Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                context.push(AppRouter.createService, extra: {
                  'organisationId': organisationId,
                  'organisationName': organisationName,
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add New Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const Divider(),
          // Services List
          Expanded(
            child: _ServicesList(
              organisationId: organisationId,
              organisationName: organisationName,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesList extends ConsumerWidget {
  final String organisationId;
  final String organisationName;

  const _ServicesList({
    required this.organisationId,
    required this.organisationName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesState = ref.watch(servicesProviderFamily(organisationId));
    final services = servicesState.services;
    final isLoading = servicesState.isLoading;
    final errorMessage = servicesState.errorMessage;

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
              'No services found',
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
        return _ServiceAdminCard(
          service: service,
          organisationId: organisationId,
          organisationName: organisationName,
          onEdit: () {
            context.push(AppRouter.editService, extra: {
              'organisationId': organisationId,
              'serviceId': service.id,
              'organisationName': organisationName,
              'serviceData': service.toFirestore(),
            });
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Service'),
                content: Text('Are you sure you want to delete "${service.name}"?'),
                actions: [
                  TextButton(
                    onPressed: () => context.pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => context.pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                await FirebaseFirestore.instance
                    .collection('organisations')
                    .doc(organisationId)
                    .collection('services')
                    .doc(service.id)
                    .delete();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Service deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting service: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          onViewQueue: () {
            context.push(AppRouter.viewQueue, extra: {
              'organisationId': organisationId,
              'organisationName': organisationName,
              'serviceId': service.id,
              'serviceName': service.name,
            });
          },
        );
      },
    );
  }
}

class _ServiceAdminCard extends StatelessWidget {
  final dynamic service;
  final String organisationId;
  final String organisationName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewQueue;

  const _ServiceAdminCard({
    required this.service,
    required this.organisationId,
    required this.organisationName,
    required this.onEdit,
    required this.onDelete,
    required this.onViewQueue,
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
                    Icons.room_service,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (service.description != null && service.description.isNotEmpty)
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
                  '~${service.averageServiceDuration ?? 5} min per person',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                    onPressed: onViewQueue,
                    icon: const Icon(Icons.people, size: 16),
                    label: const Text('Queue'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
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
