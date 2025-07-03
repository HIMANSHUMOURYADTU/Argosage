import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carbon_provider.dart';
import '../../utils/app_theme.dart';
import 'calculator_results_screen.dart';

class CalculatorInputScreen extends StatelessWidget {
  const CalculatorInputScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarbonProvider>(context, listen: false);

    return Scaffold(
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader("🌾 Crop & Farm Details"),
            _buildDropdown(provider, 'crop_type', 'Crop Type', provider.crop_emission_factors.keys.toList()),
            _buildNumberInput(provider, 'area', 'Area (hectares)'),
            _buildNumberInput(provider, 'number_of_crops', 'Crop cycles per year', isInt: true),
            const SizedBox(height: 24),
            _buildSectionHeader("🧪 Fertilizer & Pesticide"),
            _buildDropdown(provider, 'fertilizer_type', 'Fertilizer Type', provider.fertilizer_factors.keys.toList()),
            _buildNumberInput(provider, 'fertilizer_kg', 'Fertilizer used (kg/year)'),
            _buildDropdown(provider, 'pesticide_type', 'Pesticide Type', provider.pesticide_factors.keys.toList()),
            _buildNumberInput(provider, 'pesticide_l', 'Pesticide used (litres/year)'),
            const SizedBox(height: 24),
            _buildSectionHeader("💧 Machinery & Irrigation"),
            _buildDropdown(provider, 'irrigation_type', 'Irrigation Source', provider.irrigation_factors.keys.toList()),
            _buildSlider(context, 'irrigation_hours', 'Irrigation hours per year', 0, 2000),
            _buildSlider(context, 'tractor_hours', 'Tractor usage per year (hours)', 0, 1000),
            const SizedBox(height: 24),
            _buildSectionHeader("🌱 Green Practices"),
            _buildRadio(context, 'cover_crop', 'Use cover cropping/green manure?', ['Yes', 'No']),
            _buildRadio(context, 'renewable_energy', 'Use solar/wind on farm?', ['Yes', 'No']),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.calculate_rounded),
              label: const Text("Calculate Emissions"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                provider.calculateEmissions();
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CalculatorResultsScreen()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 8.0, top: 8.0), child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)));
  Widget _buildNumberInput(CarbonProvider p, String key, String label, {bool isInt = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: TextFormField(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: false), keyboardType: TextInputType.number, onChanged: (v) => p.updateInput(key, (isInt ? int.tryParse(v) : double.tryParse(v)) ?? 0)));
  Widget _buildDropdown(CarbonProvider p, String key, String label, List<String> items) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: DropdownButtonFormField<String>(decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), filled: false), items: items.map((v) => DropdownMenuItem<String>(value: v, child: Text(v))).toList(), onChanged: (v) => p.updateInput(key, v)));
  Widget _buildSlider(BuildContext context, String key, String label, double min, double max) => Consumer<CarbonProvider>(builder: (context, p, child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 8.0), child: Text('$label: ${p.inputs[key]?.toStringAsFixed(0) ?? '0'}', style: const TextStyle(color: AppTheme.lightText))), Slider(value: (p.inputs[key] ?? min).toDouble(), min: min, max: max, divisions: 20, label: (p.inputs[key] ?? min).toStringAsFixed(0), onChanged: (v) => p.updateInput(key, v))]));
  Widget _buildRadio(BuildContext context, String key, String title, List<String> options) => Consumer<CarbonProvider>(builder: (context, p, child) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(title, style: const TextStyle(color: AppTheme.lightText))), Row(children: options.map((o) => Expanded(child: RadioListTile<String>(contentPadding: EdgeInsets.zero, title: Text(o), value: o, groupValue: p.inputs[key], onChanged: (v) => p.updateInput(key, v)))).toList())]));
}