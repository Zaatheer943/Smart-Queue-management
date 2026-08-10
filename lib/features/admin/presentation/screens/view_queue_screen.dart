import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:queuewise/app/router.dart';
import 'package:queuewise/shared/models/token_model.dart';

/// Screen for admins to view and manage queues
class ViewQueueScreen extends ConsumerWidget {
  final String organisationId;
  final String organisationName;
  final String serviceId;
  final String serviceName;

  const ViewQueueScreen({
    super.key,
    required this.organisationId,
    required this.organisationName,
    required this.serviceId,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Queue - $serviceName'),
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
              // Trigger refresh
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Queue Info
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Organisation: $organisationName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Service: $serviceName',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Queue List
          Expanded(
            child: _QueueList(
              organisationId: organisationId,
              serviceId: serviceId,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  final String organisationId;
  final String serviceId;

  const _QueueList({
    required this.organisationId,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organisations')
          .doc(organisationId)
          .collection('queues')
          .where('serviceId', isEqualTo: serviceId)
          .limit(1)
          .snapshots(),
      builder: (context, queueSnapshot) {
        if (queueSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (queueSnapshot.hasError) {
          return Center(
            child: Text('Error: ${queueSnapshot.error}'),
          );
        }

        if (!queueSnapshot.hasData || queueSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No queue found for this service'),
          );
        }

        final queueDoc = queueSnapshot.data!.docs.first;
        final queueId = queueDoc.id;

        // Now fetch tokens for this queue
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('organisations')
              .doc(organisationId)
              .collection('queues')
              .doc(queueId)
              .collection('tokens')
              .where('status', whereIn: ['waiting', 'called', 'serving'])
              .orderBy('tokenNumber')
              .snapshots(),
          builder: (context, tokensSnapshot) {
            if (tokensSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (tokensSnapshot.hasError) {
              return Center(
                child: Text('Error: ${tokensSnapshot.error}'),
              );
            }

            if (!tokensSnapshot.hasData || tokensSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No one in queue'),
                  ],
                ),
              );
            }

            final tokens = tokensSnapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tokens.length,
              itemBuilder: (context, index) {
                final tokenDoc = tokens[index];
                final token = TokenModel.fromFirestore(tokenDoc);
                return _TokenCard(
                  token: token,
                  onCall: () => _callToken(context, organisationId, queueId, token),
                  onComplete: () => _completeToken(context, organisationId, queueId, token),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _callToken(
    BuildContext context,
    String organisationId,
    String queueId,
    TokenModel token,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('organisations')
          .doc(organisationId)
          .collection('queues')
          .doc(queueId)
          .collection('tokens')
          .doc(token.id)
          .update({
        'status': 'called',
        'calledAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token ${token.tokenNumber} called'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calling token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeToken(
    BuildContext context,
    String organisationId,
    String queueId,
    TokenModel token,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('organisations')
          .doc(organisationId)
          .collection('queues')
          .doc(queueId)
          .collection('tokens')
          .doc(token.id)
          .update({
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token ${token.tokenNumber} completed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing token: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TokenCard extends StatelessWidget {
  final TokenModel token;
  final VoidCallback onCall;
  final VoidCallback onComplete;

  const _TokenCard({
    required this.token,
    required this.onCall,
    required this.onComplete,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'waiting':
        return Colors.orange;
      case 'called':
        return Colors.blue;
      case 'serving':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waiting':
        return 'Waiting';
      case 'called':
        return 'Called';
      case 'serving':
        return 'Serving';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

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
                    color: _getStatusColor(token.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${token.tokenNumber}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(token.status),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        token.userName.isNotEmpty ? token.userName : 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      if (token.userEmail.isNotEmpty)
                        Text(
                          token.userEmail,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(token.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(token.status),
                          style: TextStyle(
                            color: _getStatusColor(token.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (token.userPhone.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    token.userPhone,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Joined: ${_formatTime(token.joinedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
            if (token.status == 'waiting') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onCall,
                      icon: const Icon(Icons.call, size: 16),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (token.status == 'called' || token.status == 'serving') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Complete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
