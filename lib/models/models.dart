class Senior {
  final String uid;
  final String name;
  final String branch;
  final int year;
  final List<String> skills;
  final double rating;
  final int doubtsSolved;
  final int points;
  Senior({
    required this.uid,
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
  final String id;
  final String subject;
  final String topic;
  final String description;
  final String urgency;
  final String branch;
  final String askedBy;
  String status;
  String? assignedTo;
  Doubt({
    required this.id,
    required this.subject,
    required this.topic,
    required this.description,
    required this.urgency,
    required this.branch,
    required this.askedBy,
    this.status = 'Open',
    this.assignedTo,
  });
}
