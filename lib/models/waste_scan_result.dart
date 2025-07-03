// lib/models/waste_scan_result.dart
class WasteScanResult {
  final String caption;
  final String category;
  final String binColor;
  final String explanation;

  WasteScanResult({
    required this.caption,
    required this.category,
    required this.binColor,
    required this.explanation,
  });

  factory WasteScanResult.fromJson(Map<String, dynamic> json) {
    return WasteScanResult(
      caption: json['caption'] ?? 'No caption generated.',
      category: json['category'] ?? 'Unclassified',
      binColor: json['bin_color'] ?? 'unknown',
      explanation: json['explanation'] ?? 'No explanation available.',
    );
  }
}