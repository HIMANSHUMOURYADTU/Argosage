import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/carbon_data.dart';
import '../../providers/carbon_provider.dart';
import '../../utils/app_theme.dart';

class CalculatorResultsScreen extends StatelessWidget {
  const CalculatorResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carbon Footprint Results")),
      body: Consumer<CarbonProvider>(
        builder: (context, provider, child) {
          if (provider.calculation == null) return const Center(child: Text("No calculation performed."));
          final calc = provider.calculation!;
          final area = (provider.inputs['area'] ?? 1.0).toDouble();
          final rate = area > 0 ? calc.totalEmissions / area : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTotalCard(calc.totalEmissions, rate),
              const SizedBox(height: 16),
              _buildBreakdownCard(calc.categoryEmissions),
              const SizedBox(height: 16),
              _buildChartCard(calc.categoryEmissions),
              const SizedBox(height: 16),
              _buildRecommendationsCard(calc),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(double total, double rate) {
    // ignore: unused_local_variable
    String rating; Color ratingColor;
    if (rate > 4) { rating = "High Emitter"; ratingColor = Colors.red.shade700; }
    else if (rate > 2) { rating = "Medium Emitter"; ratingColor = Colors.orange.shade700; }
    else { rating = "Low Emitter"; ratingColor = AppTheme.primary; }

    return Card(color: ratingColor, child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(children: [
        const Text("Total Farm Footprint", style: TextStyle(fontSize: 18, color: Colors.white)),
        Text("${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
        const Text("tonnes CO2e/year", style: TextStyle(color: Colors.white70)),
        const Divider(color: Colors.white54, height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _metric("Your Rate", "${rate.toStringAsFixed(2)} t/ha", Colors.white),
          _metric("National Avg", "2.2 t/ha", Colors.white70),
        ])
      ]),
    ));
  }

  Widget _metric(String label, String value, Color color) => Column(children: [Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)), Text(label, style: TextStyle(color: color.withOpacity(0.8)))]);

  Widget _buildBreakdownCard(Map<String, double> categories) => Card(child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Emission Breakdown", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...categories.entries.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: Row(children: [Expanded(child: Text(e.key)), Text("${e.value.toStringAsFixed(2)} t", style: const TextStyle(fontWeight: FontWeight.bold))]))).toList(),
    ]),
  ));

  Widget _buildChartCard(Map<String, double> categories) {
    final List<Color> pieColors = [Colors.green, Colors.blue, Colors.orange, Colors.red, Colors.purple, Colors.brown];
    int colorIndex = 0;
    final total = categories.values.fold(0.0, (prev, e) => prev + e);
    return Card(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(children: [
        const Text("Emissions Distribution", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 250, child: PieChart(
          PieChartData(
            sections: categories.entries.where((e) => e.value > 0).map((entry) {
              final color = pieColors[colorIndex++ % pieColors.length];
              final percentage = (entry.value / total * 100);
              return PieChartSectionData(color: color, value: entry.value, title: '${percentage.toStringAsFixed(0)}%', radius: 100, titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)]));
            }).toList(),
            sectionsSpace: 2, centerSpaceRadius: 40,
          ),
        )),
      ]),
    ));
  }

   Widget _buildRecommendationsCard(CarbonCalculation calc) {
    List<String> recs = [];
    if (calc.categoryEmissions["Irrigation"]! > 0.5) recs.add("💧 Switch to drip irrigation and solar pumps to cut water and energy use.");
    if (calc.categoryEmissions["Fertilizers"]! > 0.5) recs.add("🧪 Use precision farming (soil testing) to apply only the fertilizer needed.");
    if (calc.categoryEmissions["Pesticides"]! > 0.3) recs.add("🐞 Adopt Integrated Pest Management (IPM) to reduce chemical use.");
    if (calc.categoryEmissions["Crop Cultivation"]! > 2) recs.add("🌱 Rotate with nitrogen-fixing crops like pulses or use cover cropping to improve soil health.");
    if (recs.isEmpty) recs.add("✅ Your practices are highly sustainable. Keep up the great work!");

    return Card(child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Smart Recommendations", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...recs.map((rec) => ListTile(contentPadding: EdgeInsets.zero, leading: Text(rec.substring(0, 2), style: const TextStyle(fontSize: 24)), title: Text(rec.substring(3)))),
      ]),
    ));
  }
}