import 'package:flutter/material.dart';

class Senior {
  String id;
  String name;
  String branch;
  int year;
  List<String> skills;
  double rating;
  int doubtsSolved;
  int points;

  Senior({
    required this.id,
    required this.name,
    required this.branch,
    required this.year,
    required this.skills,
    required this.rating,
    required this.doubtsSolved,
    required this.points,
  });
}

class Doubt {
  String id;
  String subject;
  String topic;
  String description;
  String branch;
  String urgency;
  String status;
  String? assignedSenior;

  Doubt({
    required this.id,
    required this.subject,
    required this.topic,
    required this.description,
    required this.branch,
    required this.urgency,
    required this.status,
    this.assignedSenior,
  });
}

class ChatMessage {
  String sender;
  String message;
  DateTime time;

  ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
  });
}

class AppData {
  // ----------------------------------------------------------
  // Current user
  // ----------------------------------------------------------

  String userName = 'Bhavana Yaswanthi';
  String rollNumber = '23A81A0001';
  String userBranch = 'IT';
  int userYear = 1;
  String userRole = 'junior';

  // ----------------------------------------------------------
  // Senior mentors
  // ----------------------------------------------------------

  List<Senior> seniors = [
    Senior(
      id: 's001',
      name: 'Ananya Reddy',
      branch: 'IT',
      year: 4,
      skills: ['Java', 'DSA', 'DBMS'],
      rating: 4.9,
      doubtsSolved: 42,
      points: 420,
    ),

    Senior(
      id: 's002',
      name: 'Sai Teja',
      branch: 'CSE',
      year: 4,
      skills: ['Java', 'Python', 'DSA'],
      rating: 4.8,
      doubtsSolved: 35,
      points: 350,
    ),

    Senior(
      id: 's003',
      name: 'Harika',
      branch: 'IT',
      year: 3,
      skills: ['Python', 'DBMS', 'Web Development'],
      rating: 4.7,
      doubtsSolved: 29,
      points: 290,
    ),

    Senior(
      id: 's004',
      name: 'Rahul Varma',
      branch: 'CSE',
      year: 4,
      skills: ['Java', 'DSA', 'C'],
      rating: 4.6,
      doubtsSolved: 27,
      points: 270,
    ),

    Senior(
      id: 's005',
      name: 'Keerthana',
      branch: 'ECE',
      year: 4,
      skills: ['Python', 'IoT', 'C'],
      rating: 4.8,
      doubtsSolved: 31,
      points: 310,
    ),
  ];

  // ----------------------------------------------------------
  // Doubts
  // ----------------------------------------------------------

  List<Doubt> doubts = [
    Doubt(
      id: 'd001',
      subject: 'Java',
      topic: 'Arrays',
      description: 'I am confused about how arrays work in Java.',
      branch: 'IT',
      urgency: 'Urgent',
      status: 'open',
    ),

    Doubt(
      id: 'd002',
      subject: 'DSA',
      topic: 'Binary Search',
      description: 'Can someone explain binary search with an example?',
      branch: 'CSE',
      urgency: 'Normal',
      status: 'open',
    ),

    Doubt(
      id: 'd003',
      subject: 'DBMS',
      topic: 'Normalization',
      description: 'I need help understanding 1NF, 2NF and 3NF.',
      branch: 'IT',
      urgency: 'Important',
      status: 'open',
    ),

    Doubt(
      id: 'd004',
      subject: 'Python',
      topic: 'Functions',
      description: 'What is the difference between parameters and arguments?',
      branch: 'CSE',
      urgency: 'Normal',
      status: 'open',
    ),
  ];

  // ----------------------------------------------------------
  // Chat
  // ----------------------------------------------------------

  List<ChatMessage> messages = [
    ChatMessage(
      sender: 'Ananya Reddy',
      message: 'Hi! I can help you with your Java doubt.',
      time: DateTime.now().subtract(const Duration(minutes: 5)),
    ),

    ChatMessage(
      sender: 'You',
      message: 'Thank you! I am confused about array indexing.',
      time: DateTime.now().subtract(const Duration(minutes: 4)),
    ),

    ChatMessage(
      sender: 'Ananya Reddy',
      message: 'No problem. I will explain it with a simple example.',
      time: DateTime.now().subtract(const Duration(minutes: 3)),
    ),
  ];

  // ----------------------------------------------------------
  // SMART MATCHING
  // ----------------------------------------------------------

  List<Senior> match(String subject, String branch, int juniorYear) {
    List<Senior> matches = seniors.where((senior) {
      // Senior should be in a higher year.
      bool higherYear = senior.year > juniorYear;

      // Senior should have the required subject skill.
      bool skillMatch = senior.skills.any(
        (skill) => skill.toLowerCase() == subject.toLowerCase(),
      );

      // Same branch gets priority.
      bool branchMatch =
          senior.branch.toLowerCase() == branch.toLowerCase() ||
          senior.branch.toLowerCase() == 'cse';

      return higherYear && skillMatch && branchMatch;
    }).toList();

    // Sort by rating first.
    matches.sort((a, b) {
      int ratingResult = b.rating.compareTo(a.rating);

      if (ratingResult != 0) {
        return ratingResult;
      }

      // If rating is same, compare solved doubts.
      return b.doubtsSolved.compareTo(a.doubtsSolved);
    });

    // Maximum 3 seniors.
    return matches.take(3).toList();
  }

  // ----------------------------------------------------------
  // ADD DOUBT
  // ----------------------------------------------------------

  void addDoubt({
    required String subject,
    required String topic,
    required String description,
    required String branch,
    required String urgency,
  }) {
    doubts.insert(
      0,
      Doubt(
        id: 'd${doubts.length + 1}',
        subject: subject,
        topic: topic,
        description: description,
        branch: branch,
        urgency: urgency,
        status: 'open',
      ),
    );
  }

  // ----------------------------------------------------------
  // ASSIGN SENIOR
  // ----------------------------------------------------------

  void assignSenior(String doubtId, String seniorId) {
    final index = doubts.indexWhere((doubt) => doubt.id == doubtId);

    if (index != -1) {
      doubts[index].assignedSenior = seniorId;
      doubts[index].status = 'matched';
    }
  }

  // ----------------------------------------------------------
  // MARK AS SOLVED
  // ----------------------------------------------------------

  void markSolved(String doubtId) {
    final index = doubts.indexWhere((doubt) => doubt.id == doubtId);

    if (index == -1) {
      return;
    }

    doubts[index].status = 'solved';

    final seniorId = doubts[index].assignedSenior;

    if (seniorId == null) {
      return;
    }

    final seniorIndex = seniors.indexWhere((senior) => senior.id == seniorId);

    if (seniorIndex != -1) {
      seniors[seniorIndex].points += 10;
      seniors[seniorIndex].doubtsSolved += 1;
    }
  }

  // ----------------------------------------------------------
  // LEADERBOARD
  // ----------------------------------------------------------

  List<Senior> leaderboard() {
    List<Senior> result = List.from(seniors);

    result.sort((a, b) => b.points.compareTo(a.points));

    return result;
  }

  // ----------------------------------------------------------
  // GET SENIOR BY ID
  // ----------------------------------------------------------

  Senior? getSenior(String id) {
    try {
      return seniors.firstWhere((senior) => senior.id == id);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------------------------
  // URGENCY COLOR
  // ----------------------------------------------------------

  Color urgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'urgent':
        return Colors.red;

      case 'important':
        return Colors.orange;

      case 'normal':
        return Colors.green;

      default:
        return Colors.grey;
    }
  }
}
