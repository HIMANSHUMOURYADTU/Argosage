import 'package:codeforb/screens/missions_screens.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/farm_provider.dart';
import 'dashboard_screen.dart';
import 'pest_scanner_screen.dart';
import 'waste_scanner_screen.dart';
import 'carbon_calculator/calculator_input_screen.dart';
import 'chatbot_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    DashboardScreen(),
    PestScannerScreen(),
    WasteScannerScreen(),
    CalculatorInputScreen(),
    MissionsScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();
    // Fetch initial data for the dashboard when the app starts.
    Provider.of<FarmProvider>(context, listen: false).fetchAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle(_selectedIndex)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "EcoBot Assistant",
            icon: const Icon(Icons.support_agent_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatbotScreen()),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.pest_control_rounded), label: 'Pest Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.recycling_rounded), label: 'Waste Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: 'Carbon'),
          BottomNavigationBarItem(icon: Icon(Icons.flag_rounded), label: 'Missions'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0: return 'Dashboard';
      case 1: return 'Pest & Disease Scanner';
      case 2: return 'AI Waste Classifier';
      case 3: return 'Farm Carbon Calculator';
      case 4: return 'Sustainability Missions';
      default: return 'AgroSage';
    }
  }
}