import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  void handleNavigation(int index) {
    setState(() => selectedIndex = index);

    if (index == 1) {
      Navigator.pushNamed(context, '/ask-doubt');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/leaderboard');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  void openNotifications() {
    Navigator.pushNamed(context, '/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F6FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good morning 👋',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF777B91),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'ConnectUp',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181A2A),
              ),
            ),
          ],
        ),
        actions: [
          if (uid != null)
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId', isEqualTo: uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data?.docs
                        .where((doc) => doc.data()['read'] != true)
                        .length ??
                    0;

                return IconButton(
                  tooltip: 'Notifications',
                  onPressed: openNotifications,
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.notifications_outlined,
                        color: Color(0xFF635BFF),
                        size: 28,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -5,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 17,
                              minHeight: 17,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 99
                                  ? '99+'
                                  : '$unreadCount',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          IconButton(
            tooltip: 'My Profile',
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
            icon: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFEAE8FF),
              child: Icon(
                Icons.person,
                color: Color(0xFF635BFF),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF635BFF),
                    Color(0xFF817BFF),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF635BFF).withOpacity(0.22),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -15,
                    top: -18,
                    child: Container(
                      height: 110,
                      width: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 25,
                    bottom: -35,
                    child: Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'SMART MATCHING',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 17),
                      const Text(
                        'Need help?',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Ask a doubt and find\nthe right senior.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          height: 1.15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/ask-doubt');
                        },
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Ask a Doubt',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF635BFF),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 17,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Your activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181A2A),
              ),
            ),

            const SizedBox(height: 12),

            // Live activity counts; count depends on the user's role.
            if (uid == null)
              const Text('Please log in to see your activity.')
            else
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .snapshots(),
                builder: (context, profileSnapshot) {
                  if (profileSnapshot.hasError) {
                    return const Text('Could not load your profile.');
                  }

                  if (!profileSnapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final profile =
                      profileSnapshot.data!.data() ?? <String, dynamic>{};
                  final role =
                      '${profile['role'] ?? 'junior'}'.toLowerCase();
                  final isSenior = role == 'senior';
                  final points =
                      (profile['points'] as num?)?.toInt() ?? 0;

                  return StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('doubts')
                        .where(
                          isSenior ? 'seniorId' : 'juniorId',
                          isEqualTo: uid,
                        )
                        .snapshots(),
                    builder: (context, doubtSnapshot) {
                      if (doubtSnapshot.hasError) {
                        return const Text('Could not load activity.');
                      }

                      if (!doubtSnapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final doubts = doubtSnapshot.data!.docs;

                      final solvedDoubts = doubts.where((doc) {
                        return doc.data()['status'] == 'solved';
                      }).length;

                      return Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              number:
                                  doubts.length.toString().padLeft(2, '0'),
                              label: isSenior ? 'Assigned' : 'Doubts',
                              icon: Icons.help_outline_rounded,
                              iconColor: const Color(0xFF635BFF),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              number: solvedDoubts
                                  .toString()
                                  .padLeft(2, '0'),
                              label: 'Solved',
                              icon: Icons.check_circle_outline_rounded,
                              iconColor: const Color(0xFF18A673),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: StatCard(
                              number: '$points',
                              label: 'Points',
                              icon: Icons.stars_rounded,
                              iconColor: const Color(0xFFE49A18),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Smart matches',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF181A2A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/matching');
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF635BFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Registered seniors from Firestore
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'senior')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text('Could not load registered seniors.');
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final seniors = snapshot.data!.docs
                    .where((doc) => doc.id != uid)
                    .take(3)
                    .toList();

                if (seniors.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'No registered seniors yet. They will appear here after registration.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF777B91)),
                    ),
                  );
                }

                return Column(
                  children: seniors.map((doc) {
                    final senior = doc.data();
                    final name = '${senior['name'] ?? 'Senior'}';
                    final branch = '${senior['branch'] ?? ''}';
                    final year = '${senior['year'] ?? ''}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: MatchCard(
                        name: name,
                        initial:
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                        details: [
                          if (branch.isNotEmpty) branch,
                          if (year.isNotEmpty && year != '0')
                            'Year $year',
                          'Senior',
                        ].join(' • '),
                        skills: 'Registered Study Buddy',
                        score: 'HELP',
                        topMatch: false,
                        onTap: () {
                          Navigator.pushNamed(context, '/matching');
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF181A2A),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: QuickAction(
                    icon: Icons.emoji_events_rounded,
                    iconColor: const Color(0xFFE49A18),
                    title: 'Leaderboard',
                    subtitle: 'See top helpers',
                    onTap: () {
                      Navigator.pushNamed(context, '/leaderboard');
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QuickAction(
                    icon: Icons.person_rounded,
                    iconColor: const Color(0xFF635BFF),
                    title: 'My Profile',
                    subtitle: 'View your profile',
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            QuickAction(
              icon: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF635BFF),
              title: 'Notifications',
              subtitle: 'View requests and updates',
              onTap: openNotifications,
            ),

            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAE8FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF635BFF).withOpacity(0.08),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF635BFF),
                    size: 23,
                  ),
                  SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Learn together, help each other and grow with the Study Buddy community.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF55586B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 8,
        selectedIndex: selectedIndex,
        onDestinationSelected: handleNavigation,
        indicatorColor: const Color(0xFFEAE8FF),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: Color(0xFF635BFF),
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(
              Icons.help_rounded,
              color: Color(0xFF635BFF),
            ),
            label: 'Doubts',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(
              Icons.emoji_events_rounded,
              color: Color(0xFF635BFF),
            ),
            label: 'Ranks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(
              Icons.person_rounded,
              color: Color(0xFF635BFF),
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Activity stat card
class StatCard extends StatelessWidget {
  final String number;
  final String label;
  final IconData icon;
  final Color iconColor;

  const StatCard({
    super.key,
    required this.number,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.035)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 8),
          Text(
            number,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Color(0xFF181A2A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF777B91),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// Senior match card
class MatchCard extends StatelessWidget {
  final String name;
  final String initial;
  final String details;
  final String skills;
  final String score;
  final bool topMatch;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.name,
    required this.initial,
    required this.details,
    required this.skills,
    required this.score,
    required this.topMatch,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: topMatch
                ? const Color(0xFF635BFF).withOpacity(0.18)
                : Colors.black.withOpacity(0.035),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFEAE8FF),
                        Color(0xFFF1F0FF),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF635BFF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF181A2A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        details,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF777B91),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F8F1),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    score,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF18A673),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: Color(0xFF635BFF),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      skills,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF55586B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF18A673),
                  size: 15,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Registered Study Buddy',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF18A673),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  'View',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF635BFF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFF635BFF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Quick action card
class QuickAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withOpacity(0.035)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF181A2A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF777B91),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}