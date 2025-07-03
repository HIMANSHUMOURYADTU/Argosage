// lib/models/mission.dart

class Mission {
  final String id;
  final String title;
  final int reward;
  bool completed;

  Mission({
    required this.id,
    required this.title,
    required this.reward,
    required this.completed,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Unnamed Mission',
      reward: json['reward'] ?? 0,
      completed: json['completed'] ?? false,
    );
  }
}