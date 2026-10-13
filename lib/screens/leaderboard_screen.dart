import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final users = [
      ['Priya Sharma', 'CSE 4th Year', '1280', '42'],
      ['Arjun Kumar', 'CSE 3rd Year', '1140', '37'],
      ['Rahul Reddy', 'IT 3rd Year', '980', '31'],
      ['Sneha Patel', 'ECE 4th Year', '860', '27'],
      ['Karthik Rao', 'CSE 3rd Year', '790', '24'],
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF635BFF), Color(0xFF817BFF)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.emoji_events, color: Colors.white, size: 32),
                SizedBox(height: 10),
                Text(
                  'Top Helpers',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Help juniors, earn points and climb the leaderboard.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFEAE8FF),
                  child: Text('B'),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your rank\n#18 • 420 points',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  '+20 this week',
                  style: TextStyle(
                    color: Color(0xFF18A673),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'This month',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(users.length, (index) {
            final user = users[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: LeaderboardCard(
                rank: index + 1,
                name: user[0],
                year: user[1],
                points: user[2],
                helped: user[3],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class LeaderboardCard extends StatelessWidget {
  final int rank;
  final String name;
  final String year;
  final String points;
  final String helped;
  const LeaderboardCard({
    super.key,
    required this.rank,
    required this.name,
    required this.year,
    required this.points,
    required this.helped,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '#$rank',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF635BFF),
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: const Color(0xFFEAE8FF),
            child: Text(name[0]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '$year • helped $helped',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF777B91),
                  ),
                ),
              ],
            ),
          ),
          Text(points, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
