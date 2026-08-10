import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/core/utils/extensions.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/queues/domain/services/queue_calculation_service.dart';
import 'package:queuewise/features/queues/presentation/providers/queue_provider.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Active queue screen with real-time updates
class ActiveQueueScreen extends ConsumerStatefulWidget {
  const ActiveQueueScreen({super.key});

  @override
  ConsumerState<ActiveQueueScreen> createState() => _ActiveQueueScreenState();
}

class _ActiveQueueScreenState extends ConsumerState<ActiveQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final queueState = ref.watch(queueProviderFamily(user.uid));
    final activeToken = queueState.activeToken;
    final queue = queueState.queue;
    final isLoading = queueState.isLoading;
    final errorMessage = queueState.errorMessage;
    final peopleAhead = queueState.peopleAhead;

    // Use state token (realtime stream simplified for now)
    final displayToken = activeToken;

    if (isLoading && activeToken == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Queue')),
        body: Center(
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
                  ref.read(queueProviderFamily(user.uid).notifier).loadActiveToken(user.uid);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (displayToken == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Queue')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.queue_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No active queue',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.go(AppRouter.organisations);
                },
                child: const Text('Browse Organisations'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(queueProviderFamily(user.uid).notifier).loadActiveToken(user.uid);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Token Card
            _TokenCard(token: displayToken, queue: queue),
            const SizedBox(height: 24),

            // Queue Info Card
            _QueueInfoCard(token: displayToken, queue: queue, peopleAhead: peopleAhead),
            const SizedBox(height: 24),

            // Status Card
            _StatusCard(token: displayToken),
            const SizedBox(height: 24),

            // Cancel Button
            if (displayToken.isActive)
              ElevatedButton.icon(
                onPressed: () {
                  _showCancelDialog(displayToken);
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Queue'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(TokenModel token) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Queue'),
        content: const Text('Are you sure you want to cancel your queue token?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(queueProviderFamily(user.uid).notifier).cancelToken(token.id);
              }
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

/// Token display card
class _TokenCard extends StatelessWidget {
  final TokenModel token;
  final dynamic queue;

  const _TokenCard({required this.token, required this.queue});

  @override
  Widget build(BuildContext context) {
    final formattedToken = QueueCalculationService.formatTokenNumber(token.tokenNumber);
    final currentServing = queue?.currentServingNumber ?? 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Your Token',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formattedToken,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  label: 'Now Serving',
                  value: QueueCalculationService.formatTokenNumber(currentServing),
                ),
                _InfoItem(
                  label: 'Status',
                  value: _formatStatus(token.status),
                  valueColor: _getStatusColor(token.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status) {
      case AppConstants.tokenStatusWaiting:
        return 'Waiting';
      case AppConstants.tokenStatusCalled:
        return 'Called';
      case AppConstants.tokenStatusServing:
        return 'Serving';
      case AppConstants.tokenStatusServed:
        return 'Served';
      case AppConstants.tokenStatusCancelled:
        return 'Cancelled';
      case AppConstants.tokenStatusNoShow:
        return 'No Show';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case AppConstants.tokenStatusWaiting:
        return Colors.orange;
      case AppConstants.tokenStatusCalled:
        return Colors.blue;
      case AppConstants.tokenStatusServing:
        return Colors.green;
      case AppConstants.tokenStatusServed:
        return Colors.grey;
      case AppConstants.tokenStatusCancelled:
        return Colors.red;
      case AppConstants.tokenStatusNoShow:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

/// Queue information card
class _QueueInfoCard extends StatelessWidget {
  final TokenModel token;
  final dynamic queue;
  final int peopleAhead;

  const _QueueInfoCard({
    required this.token,
    required this.queue,
    required this.peopleAhead,
  });

  @override
  Widget build(BuildContext context) {
    final estimatedWait = token.estimatedWaitMinutes;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queue Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people_outline, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'People Ahead',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '$peopleAhead',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.access_time, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimated Wait',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        estimatedWait > 0 ? '~${estimatedWait.formatDuration}' : 'Soon',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
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

/// Status card with progress
class _StatusCard extends StatelessWidget {
  final TokenModel token;

  const _StatusCard({required this.token});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Queue Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _getProgressValue(token.status),
              backgroundColor: Colors.grey[200],
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              _getProgressMessage(token.status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  double _getProgressValue(String status) {
    switch (status) {
      case AppConstants.tokenStatusWaiting:
        return 0.3;
      case AppConstants.tokenStatusCalled:
        return 0.6;
      case AppConstants.tokenStatusServing:
        return 0.9;
      case AppConstants.tokenStatusServed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getProgressMessage(String status) {
    switch (status) {
      case AppConstants.tokenStatusWaiting:
        return 'You are in the queue. Please wait for your turn.';
      case AppConstants.tokenStatusCalled:
        return 'Your turn is approaching! Please proceed to the counter.';
      case AppConstants.tokenStatusServing:
        return 'You are currently being served.';
      case AppConstants.tokenStatusServed:
        return 'Your service has been completed.';
      case AppConstants.tokenStatusCancelled:
        return 'Your queue has been cancelled.';
      case AppConstants.tokenStatusNoShow:
        return 'You were marked as no-show.';
      default:
        return 'Unknown status';
    }
  }
}

/// Info item widget
class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
