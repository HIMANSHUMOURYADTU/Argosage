// lib/models/dashboard_data.dart


// Represents one recommendation from the AI
class Recommendation {
  final String title;
  final String details;

  Recommendation({required this.title, required this.details});

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      title: json['title'] ?? 'No Title',
      details: json['details'] ?? 'No Details',
    );
  }
}

// Represents the entire payload for the dashboard
class DashboardData {
  final int sustainabilityScore;
  final int activeMissions;
  final int carbonCredits;
  final List<Recommendation> recommendations;

  DashboardData({
    required this.sustainabilityScore,
    required this.activeMissions,
    required this.carbonCredits,
    required this.recommendations,
  });

  // A factory constructor to create a DashboardData object from JSON
  factory DashboardData.fromJson(Map<String, dynamic> json) {
    var recsList = json['recommendations'] as List? ?? [];
    List<Recommendation> recommendations = recsList.map((i) => Recommendation.fromJson(i)).toList();

    return DashboardData(
      sustainabilityScore: json['sustainability_score'] ?? 0,
      activeMissions: json['active_missions'] ?? 0,
      carbonCredits: json['carbon_credits'] ?? 0,
      recommendations: recommendations,
    );
  }

  // A factory for creating empty/initial data
  factory DashboardData.initial() {
    return DashboardData(
        sustainabilityScore: 0,
        activeMissions: 0,
        carbonCredits: 0,
        recommendations: []);
  }
}