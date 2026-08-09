import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/features/organisations/presentation/providers/organisation_provider.dart';
import 'package:queuewise/shared/models/organisation_model.dart';

/// Organisations list screen
class OrganisationsScreen extends ConsumerStatefulWidget {
  const OrganisationsScreen({super.key});

  @override
  ConsumerState<OrganisationsScreen> createState() =>
      _OrganisationsScreenState();
}

class _OrganisationsScreenState extends ConsumerState<OrganisationsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final organisationsState = ref.watch(organisationsProvider);
    final organisations = organisationsState.organisations;
    final isLoading = organisationsState.isLoading;
    final errorMessage = organisationsState.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisations'),
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search organisations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(organisationsProvider.notifier)
                              .loadOrganisations();
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  ref.read(organisationsProvider.notifier).loadOrganisations();
                } else {
                  ref
                      .read(organisationsProvider.notifier)
                      .searchOrganisations(value);
                }
              },
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(organisations, isLoading, errorMessage),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<OrganisationModel> organisations,
    bool isLoading,
    String? errorMessage,
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
            Icon(Icons.business_outlined,
                size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No organisations found',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: organisations.length,
      itemBuilder: (context, index) {
        final organisation = organisations[index];
        return _OrganisationCard(
          organisation: organisation,
          onTap: () {
            // Navigate to services screen
            context.go('${AppRouter.organisations}/${organisation.id}/services');
          },
        );
      },
    );
  }
}

/// Organisation card widget
class _OrganisationCard extends StatelessWidget {
  final OrganisationModel organisation;
  final VoidCallback onTap;

  const _OrganisationCard({
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
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.business,
                      color: Theme.of(context).colorScheme.primary,
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
              if (organisation.address.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
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
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
