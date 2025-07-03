// lib/providers/carbon_provider.dart
import 'package:flutter/material.dart';
import '../models/carbon_data.dart';

class CarbonProvider with ChangeNotifier {
  // Input data from the user
  Map<String, dynamic> inputs = {};

  // Emission factors (hardcoded from your Streamlit app)
  final Map<String, double> crop_emission_factors = {"Rice": 2.7, "Wheat": 1.4, "Sugarcane": 1.6, "Maize": 1.2, "Pulses": 0.8, "Cotton": 1.9, "Oilseeds": 1.1, "Vegetables": 0.9, "Fruits": 0.7, "Other": 1.0};
  final Map<String, double> fertilizer_factors = {"Urea": 1.59, "DAP": 1.5, "Potash": 0.5, "Organic Compost": 0.2};
  final Map<String, double> pesticide_factors = {"Chemical": 5.0, "Organic": 1.5};
  final double tractor_factor = 2.5;
  final Map<String, double> irrigation_factors = {"Rainfed": 0, "Electric Pump": 0.5, "Diesel Pump": 1.5, "Solar Pump": 0.1};

  CarbonCalculation? calculation;

  void updateInput(String key, dynamic value) {
    inputs[key] = value;
    notifyListeners();
  }

  void calculateEmissions() {
    // Default values to avoid errors if user hasn't touched a field
    final crop_type = inputs['crop_type'] ?? 'Rice';
    final area = inputs['area'] ?? 0.0;
    final fertilizer_type = inputs['fertilizer_type'] ?? 'Urea';
    final fertilizer_kg = inputs['fertilizer_kg'] ?? 0.0;
    final pesticide_type = inputs['pesticide_type'] ?? 'Chemical';
    final pesticide_l = inputs['pesticide_l'] ?? 0.0;
    final tractor_hours = inputs['tractor_hours'] ?? 0.0;
    final irrigation_type = inputs['irrigation_type'] ?? 'Rainfed';
    final irrigation_hours = inputs['irrigation_hours'] ?? 0.0;
    final number_of_crops = inputs['number_of_crops'] ?? 1.0;
    final renewable_energy = inputs['renewable_energy'] == 'Yes';
    final cover_crop = inputs['cover_crop'] == 'Yes';

    // Calculations from your Streamlit app
    double crop_emission = crop_emission_factors[crop_type]! * area * number_of_crops;
    double fertilizer_emission = (fertilizer_kg * fertilizer_factors[fertilizer_type]!) / 1000;
    double pesticide_emission = (pesticide_l * pesticide_factors[pesticide_type]!) / 1000;
    double tractor_emission = (tractor_hours * tractor_factor) / 1000;
    double irrigation_emission = (irrigation_factors[irrigation_type]! * irrigation_hours * area) / 1000;

    double renewable_reduction = renewable_energy ? 0.1 : 0.0;
    double cover_crop_reduction = cover_crop ? 0.05 : 0.0;

    double adjusted_crop_emission = crop_emission * (1 - cover_crop_reduction);
    double adjusted_irrigation_emission = irrigation_emission * (1 - renewable_reduction);

    final categoryEmissions = {
      "Crop Cultivation": double.parse(adjusted_crop_emission.toStringAsFixed(2)),
      "Fertilizers": double.parse(fertilizer_emission.toStringAsFixed(2)),
      "Pesticides": double.parse(pesticide_emission.toStringAsFixed(2)),
      "Machinery": double.parse(tractor_emission.toStringAsFixed(2)),
      "Irrigation": double.parse(adjusted_irrigation_emission.toStringAsFixed(2))
    };

    final totalEmissions = double.parse(categoryEmissions.values.reduce((a, b) => a + b).toStringAsFixed(2));

    calculation = CarbonCalculation(
      categoryEmissions: categoryEmissions,
      totalEmissions: totalEmissions,
    );

    notifyListeners();
  }
}