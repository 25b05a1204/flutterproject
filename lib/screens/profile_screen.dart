
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String suffix(int year) {
    if (year == 1) return 'st';
    if (year == 2) return 'nd';
    if (year == 3) return 'rd';
    return 'th';
  }

  Future<void> edit(Map<String, dynamic> profile) async {
    final nameController =
        TextEditingController(text: '${profile['name'] ?? ''}');
    final branchController =
        TextEditingController(text: '${profile['branch'] ?? ''}');

    int year = int.tryParse('${profile['year'] ?? 2}') ?? 2;
    if (year < 1 || year > 4) year = 2;

    String role = '${profile['role'] ?? 'junior'}'.toLowerCase();
    if (role != 'senior') role = 'junior';

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                TextField(
                  controller: branchController,
                  decoration: const InputDecoration(labelText: 'Branch'),
                ),
                DropdownButtonFormField<int>(
                  value: year,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: [1, 2, 3, 4]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text('${v}${suffix(v)} Year'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => year = v);
                  },
                ),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(
                        value: 'junior', child: Text('Junior')),
                    DropdownMenuItem(
                        value: 'senior', child: Text('Senior')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDialogState(() => role = v);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != true) {
      nameController.dispose();
      branchController.dispose();
      return;
    }

    if (nameController.text.trim().isEmpty) {
      nameController.dispose();
      branchController.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name cannot be empty')),
        );
      }
      return;
    }

    try {
      await FirestoreService.instance.updateProfile(
        name: nameController.text.trim(),
        branch: branchController.text.trim(),
        year: year,
        role: role,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update profile: $e')),
        );
      }
    } finally {
      nameController.dispose();
      branchController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in.')),
      );
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load profile.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data!.data() ?? <String, dynamic>{};
          final name =
              '${profile['name'] ?? user.displayName ?? 'Student'}';
          final email = '${profile['email'] ?? user.email ?? ''}';
          final branch = '${profile['branch'] ?? ''}';
          final year = '${profile['year'] ?? ''}';
          final role = '${profile['role'] ?? 'junior'}'.toLowerCase();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: const TextStyle(fontSize: 30),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(email, textAlign: TextAlign.center),
              Text(
                '$branch $year Year • ${role.toUpperCase()}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              if (role == 'senior')
                _SeniorSolvedCount(seniorId: user.uid),

              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () => edit(profile),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('My Doubts'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyDoubtsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.emoji_events_outlined),
                title: const Text('Leaderboard'),
                onTap: () => Navigator.pushNamed(context, '/leaderboard'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SeniorSolvedCount extends StatelessWidget {
  final String seniorId;

  const _SeniorSolvedCount({required this.seniorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('doubts')
          .where('seniorId', isEqualTo: seniorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: ListTile(
              title: Text('Solved Doubts'),
              subtitle: Text('Could not load count.'),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Card(
            child: ListTile(
              title: Text('Solved Doubts'),
              trailing: CircularProgressIndicator(),
            ),
          );
        }

        final count = snapshot.data!.docs
            .where((doc) => doc.data()['status'] == 'solved')
            .length;

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.check_circle,
              color: Colors.green,
            ),
            title: const Text('Solved Doubts'),
            trailing: Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MyDoubtsPage extends StatelessWidget {
  const MyDoubtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('My Doubts')),
      body: uid == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('doubts')
                  .where('juniorId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load doubts. Check connection or permissions.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('You have not posted any doubts yet.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final doubt = doc.data();
                    final status = '${doubt['status'] ?? 'open'}';
                    final solved = status == 'solved';
                    final hasSenior =
                        '${doubt['seniorId'] ?? ''}'.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${doubt['title'] ?? 'Untitled doubt'}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${doubt['category'] ?? ''} • $status',
                              style: TextStyle(
                                color: solved ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('${doubt['description'] ?? ''}'),
                            if (hasSenior) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Assigned senior: ${doubt['seniorName'] ?? 'Senior'}',
                              ),
                            ],
                            const SizedBox(height: 12),

                            if (solved)
                              const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Solved',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            else if (hasSenior &&
                                (status == 'accepted' ||
                                    status == 'requested'))
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      await FirestoreService.instance
                                          .markDoubtSolved(doc.id);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Doubt marked as solved!',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not mark as solved: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  label: const Text('Mark as Solved'),
                                ),
                              )
                            else
                              const Text(
                                'Waiting for a senior to accept this doubt.',
                              ),
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

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: uid == null
          ? const Center(child: Text('Please log in'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load notifications.'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No notifications yet.'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final notification = doc.data();
                    final isRead = notification['read'] == true;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: Icon(
                          isRead
                              ? Icons.notifications_none
                              : Icons.notifications_active,
                          color: isRead ? Colors.grey : Colors.deepPurple,
                        ),
                        title: Text(
                          '${notification['title'] ?? 'Notification'}',
                        ),
                        subtitle: Text('${notification['body'] ?? ''}'),
                        trailing: isRead
                            ? const Icon(Icons.done, color: Colors.green)
                            : TextButton(
                                onPressed: () async {
                                  try {
                                    await FirestoreService.instance
                                        .markNotificationRead(doc.id);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not update notification: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Mark as Read'),
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
