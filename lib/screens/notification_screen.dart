
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in again.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Unable to load notifications. Check Firestore rules.'),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs.toList()
            ..sort((a, b) {
              final aTime = a.data()['createdAt'] as Timestamp?;
              final bTime = b.data()['createdAt'] as Timestamp?;
              return (bTime?.millisecondsSinceEpoch ?? 0)
                  .compareTo(aTime?.millisecondsSinceEpoch ?? 0);
            });

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none, size: 58, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No notifications yet.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final type = (data['type'] ?? '').toString();
              final requestId = (data['requestId'] ?? '').toString();
              final isRead = data['read'] == true;
              final isRequest = type == 'doubt_request';
              final isAccepted = type == 'request_accepted';

              return Card(
                color: isRead ? Colors.white : const Color(0xFFF0EEFF),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFFE3E0FF),
                            child: Icon(
                              isAccepted
                                  ? Icons.check_circle
                                  : Icons.notifications_active,
                              color: const Color(0xFF635BFF),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['title'] ?? 'Notification').toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  (data['body'] ?? '').toString(),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            const Icon(
                              Icons.circle,
                              size: 9,
                              color: Color(0xFF635BFF),
                            ),
                        ],
                      ),
                      if (isRequest && requestId.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                            stream: FirebaseFirestore.instance
                                .collection('requests')
                                .doc(requestId)
                                .snapshots(),
                            builder: (context, requestSnapshot) {
                              if (!requestSnapshot.hasData ||
                                  !requestSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }

                              final request = requestSnapshot.data!.data()!;
                              final status =
                                  (request['status'] ?? 'pending').toString();

                              if (status == 'accepted') {
                                return ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/chat',
                                      arguments: {
                                        'requestId': requestId,
                                        'seniorName':
                                            request['juniorName'] ?? 'Student',
                                        'doubtTitle':
                                            request['doubtTitle'] ?? 'Study doubt',
                                        'doubtDescription':
                                            request['doubtDescription'] ?? '',
                                      },
                                    );
                                  },
                                  icon: const Icon(Icons.chat),
                                  label: const Text('Open Chat'),
                                );
                              }

                              if (status != 'pending') {
                                return Text('Request status: $status');
                              }

                              return ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await FirestoreService.instance
                                        .acceptRequest(requestId: requestId);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Request accepted! Opening chat...',
                                        ),
                                      ),
                                    );

                                    Navigator.pushNamed(
                                      context,
                                      '/chat',
                                      arguments: {
                                        'requestId': requestId,
                                        'seniorName':
                                            request['juniorName'] ?? 'Student',
                                        'doubtTitle':
                                            request['doubtTitle'] ?? 'Study doubt',
                                        'doubtDescription':
                                            request['doubtDescription'] ?? '',
                                      },
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not accept request: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Accept Request'),
                              );
                            },
                          ),
                        ),
                      ],
                      if (isAccepted && requestId.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await FirebaseFirestore.instance
                                    .collection('requests')
                                    .doc(requestId)
                                    .get()
                                    .then((requestDoc) {
                                  final request = requestDoc.data();
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'requestId': requestId,
                                      'seniorName':
                                          request?['seniorName'] ?? 'Senior',
                                      'doubtTitle':
                                          request?['doubtTitle'] ?? 'Study doubt',
                                      'doubtDescription':
                                          request?['doubtDescription'] ?? '',
                                    },
                                  );
                                });
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open chat.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.chat),
                            label: const Text('Open Chat'),
                          ),
                        ),
                      ],
                      if (!isRead) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () async {
                              try {
                                await FirestoreService.instance
                                    .markNotificationRead(doc.id);
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not update notification.'),
                                  ),
                                );
                              }
                            },
                            child: const Text('Mark as read'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
