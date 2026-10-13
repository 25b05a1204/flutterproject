
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firestore_service.dart';

const Color primaryPurple = Color(0xFF635BFF);
const Color lightPurple = Color(0xFFEAE8FF);
const Color pageBackground = Color(0xFFF7F7FC);

class MatchingScreen extends StatelessWidget {
  const MatchingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final doubtId = data['doubtId']?.toString();
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        backgroundColor: pageBackground,
        elevation: 0,
        title: const Text(
          'Find Your Study Buddy ✨',
          style: TextStyle(
            color: Color(0xFF20213A),
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: primaryPurple),
      ),
      body: Column(
        children: [
          // Welcome banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryPurple, Color(0xFF938BFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You don’t have to\nstudy alone! 📚',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 9),
                      Text(
                        'Connect with seniors and clear your doubts.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                Text('🎓', style: TextStyle(fontSize: 54)),
              ],
            ),
          ),

          // Selected doubt card
          if (doubtId != null && doubtId.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lightPurple),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📝 YOUR DOUBT',
                    style: TextStyle(
                      color: primaryPurple,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${data['title'] ?? 'My study doubt'}',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF20213A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${data['description'] ?? 'Find a senior who can help you.'}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF77788C),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: lightPurple,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '📚 ${data['category'] ?? 'General'}',
                      style: const TextStyle(
                        color: primaryPurple,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Section heading
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Meet your seniors 👋',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF20213A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Choose someone to help you learn.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF77788C),
                        ),
                      ),
                    ],
                  ),
                ),
                Text('🌟', style: TextStyle(fontSize: 27)),
              ],
            ),
          ),

          Expanded(
            child: uid == null
                ? const Center(child: Text('Please log in again.'))
                : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('role', isEqualTo: 'senior')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Could not load seniors. Please check your '
                              'internet connection and Firestore rules.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: primaryPurple,
                          ),
                        );
                      }

                      final seniors = snapshot.data!.docs
                          .where((doc) => doc.id != uid)
                          .toList();

                      if (seniors.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🧑‍🎓', style: TextStyle(fontSize: 65)),
                                const SizedBox(height: 12),
                                const Text(
                                  'No seniors available yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ask another student to register and select '
                                  'the Senior role.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF77788C),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        itemCount: seniors.length,
                        itemBuilder: (context, index) {
                          final doc = seniors[index];
                          final senior = doc.data();

                          final name = '${senior['name'] ?? 'Senior'}';
                          final branch = '${senior['branch'] ?? ''}';
                          final year = '${senior['year'] ?? ''}';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 13),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryPurple.withValues(alpha: 0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFEAE8FF),
                                            Color(0xFFF4E9FF),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Center(
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : 'S',
                                          style: const TextStyle(
                                            fontSize: 23,
                                            fontWeight: FontWeight.bold,
                                            color: primaryPurple,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF20213A),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            [
                                              if (branch.isNotEmpty) branch,
                                              if (year.isNotEmpty &&
                                                  year != '0')
                                                'Year $year',
                                            ].join(' • ').isEmpty
                                                ? 'Study Buddy Senior'
                                                : [
                                                    if (branch.isNotEmpty)
                                                      branch,
                                                    if (year.isNotEmpty &&
                                                        year != '0')
                                                      'Year $year',
                                                  ].join(' • '),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF77788C),
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          const Text(
                                            '🟢 Registered senior',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF16865F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        doubtId == null || doubtId.isEmpty
                                            ? () {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Please post a doubt '
                                                      'first, then choose a senior.',
                                                    ),
                                                  ),
                                                );
                                              }
                                            : () async {
                                                try {
                                                  final requestId =
                                                      await FirestoreService
                                                          .instance
                                                          .requestSenior(
                                                    doubtId: doubtId,
                                                    senior: {
                                                      ...senior,
                                                      'uid': doc.id,
                                                    },
                                                  );

                                                  if (!context.mounted) return;

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        '🎉 Request sent to $name!',
                                                      ),
                                                    ),
                                                  );

                                                  debugPrint(
                                                    'Request created: $requestId',
                                                  );

                                                  Navigator.pushNamed(
                                                    context,
                                                    '/notifications',
                                                  );
                                                } catch (e) {
                                                  if (!context.mounted) return;

                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'Request failed: $e',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                    icon: const Icon(Icons.send_rounded),
                                    label: const Text(
                                      'Send Help Request',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryPurple,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 13,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
