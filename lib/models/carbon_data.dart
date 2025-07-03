// lib/models/carbon_data.dart

class CarbonCalculation {
  // A map to store the emissions for each category,
  // e.g., {"Crop Cultivation": 10.5, "Fertilizers": 2.1}
  final Map<String, double> categoryEmissions;

  // The final calculated total of all emissions.
  final double totalEmissions;

  // The constructor to create an instance of this class.
  CarbonCalculation({
    required this.categoryEmissions,
    required this.totalEmissions,
  });
}