// lib/screens/missions_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import '../utils/app_theme.dart';
import '../models/mission.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sustainability Missions"),
      ),
      body: Consumer<FarmProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.Loading && provider.missions.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.missions.isEmpty) {
            return const Center(child: Text("No missions available right now."));
          }

          final completedMissions = provider.missions.where((m) => m.completed).toList();
          final activeMissions = provider.missions.where((m) => !m.completed).toList();
          
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text("Active Missions", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (activeMissions.isEmpty) const Text("All missions completed! 🎉", style: TextStyle(color: AppTheme.lightText, fontSize: 16)),
              ...activeMissions.map((mission) => _buildMissionCard(context, mission, provider)),
              
              const SizedBox(height: 24),
              const Text("Completed", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...completedMissions.map((mission) => _buildMissionCard(context, mission, provider)),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMissionCard(BuildContext context, Mission mission, FarmProvider provider) {
    return Card(
      color: mission.completed ? AppTheme.primary.withOpacity(0.08) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Row(
          children: [
            Icon(
              mission.completed ? Icons.check_circle : Icons.outlined_flag,
              color: mission.completed ? AppTheme.primary : AppTheme.accent,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: mission.completed ? TextDecoration.lineThrough : TextDecoration.none,
                      color: mission.completed ? AppTheme.lightText : AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "+${mission.reward} Carbon Credits",
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (!mission.completed)
              ElevatedButton(
                onPressed: () {
                  // Show a confirmation dialog
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Complete Mission?"),
                      content: Text("Have you completed '${mission.title}'?"),
                      actions: [
                        TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(ctx).pop()),
                        ElevatedButton(child: const Text("Confirm"), onPressed: () {
                          provider.completeMission(mission.id);
                          Navigator.of(ctx).pop();
                        }),
                      ],
                    ),
                  );
                },
                child: const Text("Done"),
              ),
          ],
        ),
      ),
    );
  }
}