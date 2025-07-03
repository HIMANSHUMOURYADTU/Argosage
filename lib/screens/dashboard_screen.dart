// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../providers/farm_provider.dart';
import '../utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FarmProvider>(
          builder: (context, farmProvider, child) {
            if (farmProvider.state == ViewState.Loading && farmProvider.dashboardData.recommendations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (farmProvider.state == ViewState.Error) {
              return const Center(child: Text("Could not fetch data. Please try again."));
            }

            final data = farmProvider.dashboardData;
            return RefreshIndicator(
              onRefresh: () => farmProvider.fetchAllData(),
              child: ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  // --- Header ---
                  const Text("Welcome Back,", style: TextStyle(fontSize: 20, color: AppTheme.lightText)),
                  const Text("AgroSage Farmer", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.darkText)),
                  const SizedBox(height: 24),

                  // --- Sustainability Score Card ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Sustainability Score", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                            const SizedBox(height: 4),
                            Text("${data.sustainabilityScore}", style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        CircularPercentIndicator(
                          radius: 50.0,
                          lineWidth: 8.0,
                          percent: (data.sustainabilityScore / 100.0).clamp(0.0, 1.0),
                          center: const Icon(Icons.shield_rounded, color: Colors.white, size: 40),
                          progressColor: AppTheme.accent,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          circularStrokeCap: CircularStrokeCap.round,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Grid Stats ---
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStatCard("Carbon Credits", data.carbonCredits.toString(), Icons.eco, Colors.lightBlue),
                      _buildStatCard("Active Missions", data.activeMissions.toString(), Icons.flag, Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- AI Recommendations ---
                  const Text("AI Recommendations", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (data.recommendations.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("✅ No urgent recommendations. Your farm is looking great!", textAlign: TextAlign.center),
                      ),
                    )
                  else
                    ...data.recommendations.map((rec) => Card(
                      child: ListTile(
                        leading: const CircleAvatar(backgroundColor: AppTheme.accent, child: Icon(Icons.lightbulb, color: Colors.white, size: 20)),
                        title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(rec.details, style: const TextStyle(color: AppTheme.lightText)),
                      ),
                    )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: AppTheme.lightText)),
                Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}