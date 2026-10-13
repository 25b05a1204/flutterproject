import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE8FF),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Color(0xFF635BFF),
                  size: 30,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Choose your role',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF181A2A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tell us how you want to use ConnectUp.',
                style: TextStyle(fontSize: 15, color: Color(0xFF777B91)),
              ),
              const SizedBox(height: 35),
              RoleCard(
                icon: Icons.school_rounded,
                iconColor: const Color(0xFF635BFF),
                title: 'I am a Junior',
                subtitle:
                    'Ask doubts, find helpful seniors and learn from their experience.',
                tag: 'ASK & LEARN',
                onTap: () async {
                  final u = FirebaseAuth.instance.currentUser;
                  if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'role': 'junior'}, SetOptions(merge: true));
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const SizedBox(height: 18),
              RoleCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFF18A673),
                title: 'I am a Senior',
                subtitle: 'Help juniors, share your knowledge and earn points.',
                tag: 'HELP & EARN',
                onTap: () async {
                  final u = FirebaseAuth.instance.currentUser;
                  if (u != null) await FirebaseFirestore.instance.collection('users').doc(u.uid).set({'role': 'senior'}, SetOptions(merge: true));
                  if (context.mounted) Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF635BFF)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can change your profile role later.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF777B91),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;
  final VoidCallback onTap;
  const RoleCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(23),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: iconColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: iconColor, size: 29),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF777B91),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF777B91),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
