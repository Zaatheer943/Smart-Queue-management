import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queuewise/app/constants/app_constants.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/features/authentication/presentation/providers/auth_provider.dart';
import 'package:queuewise/features/queues/presentation/providers/queue_provider.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Staff queue management screen for operators
class StaffQueueScreen extends ConsumerStatefulWidget {
  final String organisationId;
  final String organisationName;
  final String serviceId;
  final String serviceName;

  const StaffQueueScreen({
    super.key,
    required this.organisationId,
    required this.organisationName,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  ConsumerState<StaffQueueScreen> createState() => _StaffQueueScreenState();
}

class _StaffQueueScreenState extends ConsumerState<StaffQueueScreen> {
  String? _queueId;
  TokenModel? _currentServingToken;
  TokenModel? _nextToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Staff - ${widget.serviceName}'),
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
              setState(() {
                _queueId = null;
                _currentServingToken = null;
                _nextToken = null;
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.organisationsCollection)
            .doc(widget.organisationId)
            .collection(AppConstants.queuesCollection)
            .where('serviceId', isEqualTo: widget.serviceId)
            .limit(1)
            .snapshots(),
        builder: (context, queueSnapshot) {
          if (queueSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!queueSnapshot.hasData || queueSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final queueDoc = queueSnapshot.data!.docs.first;
          _queueId = queueDoc.id;

          return StreamBuilder<QuerySnapshot>(
            stream: queueDoc.reference
                .collection(AppConstants.tokensCollection)
                .where('status', whereIn: [
                  AppConstants.tokenStatusCalled,
                  AppConstants.tokenStatusServing,
                  AppConstants.tokenStatusWaiting,
                ])
                .orderBy('tokenNumber')
                .snapshots(),
            builder: (context, tokensSnapshot) {
              if (tokensSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!tokensSnapshot.hasData) {
                return _buildEmptyState();
              }

              final tokens = tokensSnapshot.data!.docs
                  .map((doc) => TokenModel.fromFirestore(doc))
                  .toList();

              _currentServingToken = tokens.firstWhere(
                (t) => t.isCalled || t.isServing,
                orElse: () => tokens.first,
              );

              _nextToken = tokens.length > 1 ? tokens[1] : null;

              return _buildQueueContent(tokens, queueDoc);
            },
          );
        },
      ),
    );
  }

  Widget _buildQueueContent(List<TokenModel> tokens, DocumentSnapshot queueDoc) {
    final currentServing = queueDoc['currentServingNumber'] as int? ?? 0;
    final totalWaiting = queueDoc['totalWaiting'] as int? ?? 0;

    return Column(
      children: [
        // Current Serving Card
        _CurrentServingCard(
          token: _currentServingToken,
          currentServingNumber: currentServing,
        ),
        const Divider(height: 32),
        // Queue List
        Expanded(
          child: _QueueList(
            tokens: tokens,
            organisationId: widget.organisationId,
            queueId: _queueId!,
          ),
        ),
        // Action Buttons
        _ActionButtons(
          currentServingToken: _currentServingToken,
          nextToken: _nextToken,
          organisationId: widget.organisationId,
          queueId: _queueId!,
          totalWaiting: totalWaiting,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No queue found',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Customers can join this queue from the app',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CurrentServingCard extends StatelessWidget {
  final TokenModel? token;
  final int currentServingNumber;

  const _CurrentServingCard({
    required this.token,
    required this.currentServingNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        color: Colors.grey.shade100,
        child: Column(
          children: [
            Text(
              'NOW SERVING',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'No customer',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.grey.shade400,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Column(
        children: [
          Text(
            'NOW SERVING',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '#${token!.tokenNumber}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          if (token!.userName.isNotEmpty)
            Text(
              token!.userName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (token!.userPhone.isNotEmpty)
            Text(
              token!.userPhone,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(token!.status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _getStatusText(token!.status),
              style: TextStyle(
                color: _getStatusColor(token!.status),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
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

class _QueueList extends StatelessWidget {
  final List<TokenModel> tokens;
  final String organisationId;
  final String queueId;

  const _QueueList({
    required this.tokens,
    required this.organisationId,
    required this.queueId,
  });

  @override
  Widget build(BuildContext context) {
    if (tokens.isEmpty) {
      return Center(
        child: Text(
          'No customers in queue',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: tokens.length,
      itemBuilder: (context, index) {
        final token = tokens[index];
        return _TokenListItem(token: token);
      },
    );
  }
}

class _TokenListItem extends StatelessWidget {
  final TokenModel token;

  const _TokenListItem({required this.token});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(token.status).withValues(alpha: 0.1),
          child: Text(
            '#${token.tokenNumber}',
            style: TextStyle(
              color: _getStatusColor(token.status),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          token.userName.isNotEmpty ? token.userName : 'Unknown',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(_getStatusText(token.status)),
        trailing: Icon(
          _getStatusIcon(token.status),
          color: _getStatusColor(token.status),
        ),
      ),
    );
  }

  String _getStatusText(String status) {
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

  IconData _getStatusIcon(String status) {
    switch (status) {
      case AppConstants.tokenStatusWaiting:
        return Icons.access_time;
      case AppConstants.tokenStatusCalled:
        return Icons.notifications_active;
      case AppConstants.tokenStatusServing:
        return Icons.person;
      case AppConstants.tokenStatusServed:
        return Icons.check_circle;
      case AppConstants.tokenStatusCancelled:
        return Icons.cancel;
      case AppConstants.tokenStatusNoShow:
        return Icons.person_off;
      default:
        return Icons.help;
    }
  }
}

class _ActionButtons extends ConsumerWidget {
  final TokenModel? currentServingToken;
  final TokenModel? nextToken;
  final String organisationId;
  final String queueId;
  final int totalWaiting;

  const _ActionButtons({
    required this.currentServingToken,
    required this.nextToken,
    required this.organisationId,
    required this.queueId,
    required this.totalWaiting,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueNotifier = ref.read(queueProviderFamily('staff').notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Call Next Button
          if (nextToken != null || currentServingToken == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: totalWaiting > 0
                    ? () async {
                        final called = await queueNotifier.callNextCustomer(
                          organisationId,
                          queueId,
                        );
                        if (called == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No customers waiting')),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Call Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          // Current Customer Actions
          if (currentServingToken != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentServingToken!.isCalled
                        ? () async {
                            await queueNotifier.startServing(currentServingToken!.id);
                          }
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: currentServingToken!.isServing
                        ? () async {
                            await queueNotifier.completeService(currentServingToken!.id);
                          }
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await queueNotifier.skipCustomer(currentServingToken!.id);
                    },
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: currentServingToken!.isNoShow
                        ? () async {
                            await queueNotifier.recallCustomer(currentServingToken!.id);
                          }
                        : null,
                    icon: const Icon(Icons.replay),
                    label: const Text('Recall'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
