import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/carbon_provider.dart';
import 'providers/farm_provider.dart';
import 'screens/main_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FarmProvider()),
        ChangeNotifierProvider(create: (_) => CarbonProvider()),
      ],
      child: const AgroSageSuperApp(),
    ),
  );
}

class AgroSageSuperApp extends StatelessWidget {
  const AgroSageSuperApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroSage Toolkit',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}