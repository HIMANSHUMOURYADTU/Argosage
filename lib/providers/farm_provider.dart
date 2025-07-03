import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/api_sevice.dart'; // Ensure correct path to your service
import '../models/dashboard_data.dart';
import '../models/mission.dart';
import '../models/pest_scan_result.dart';
import '../models/waste_scan_result.dart';

enum ViewState { Idle, Loading, Error }

class FarmProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  ViewState _state = ViewState.Idle;
  DashboardData _dashboardData = DashboardData.initial();
  List<Mission> _missions = [];
  PestScanResult? _pestScanResult;
  WasteScanResult? _wasteScanResult;

  ViewState get state => _state;
  DashboardData get dashboardData => _dashboardData;
  List<Mission> get missions => _missions;
  PestScanResult? get pestScanResult => _pestScanResult;
  WasteScanResult? get wasteScanResult => _wasteScanResult;

  void _setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  // --- No changes needed in these methods ---
  Future<void> fetchAllData() async {
    _setState(ViewState.Loading);
    await Future.wait([fetchDashboardData(), fetchMissions()]);
    _setState(ViewState.Idle);
  }

  Future<void> fetchDashboardData() async {
    final data = await _apiService.getDashboardData();
    if (data != null) {
      _dashboardData = data;
    } else {
      _setState(ViewState.Error);
    }
    notifyListeners();
  }

  Future<void> fetchMissions() async {
    _missions = await _apiService.getMissions();
    notifyListeners();
  }

  Future<void> completeMission(String missionId) async {
    final missionIndex = _missions.indexWhere((m) => m.id == missionId);
    if (missionIndex != -1 && !_missions[missionIndex].completed) {
      _missions[missionIndex].completed = true;
      notifyListeners();
      final success = await _apiService.completeMission(missionId);
      if (success) {
        await fetchDashboardData();
      } else {
        _missions[missionIndex].completed = false;
        notifyListeners();
      }
    }
  }

  // --- UNIFIED SCANNING METHODS ---

  /// UNIFIED: Scans a pest image. Works on both mobile and web.
  /// Replaces scanPestFromImage and scanPestFromBytes.
  Future<void> scanPest(XFile imageFile) async {
    _setState(ViewState.Loading);
    _pestScanResult = null; // Clear previous result
    
    // Call the single, unified method in your ApiService
    final result = await _apiService.scanPest(imageFile);

    _pestScanResult = result;
    _setState(result == null ? ViewState.Error : ViewState.Idle);
  }

  /// UNIFIED: Classifies a waste image. Works on both mobile and web.
  /// Replaces scanWasteFromImage and scanWasteFromBytes.
  Future<void> classifyWaste(XFile imageFile) async {
    _setState(ViewState.Loading);
    _wasteScanResult = null; // Clear previous result

    // Call the single, unified method in your ApiService
    final result = await _apiService.classifyWaste(imageFile);

    _wasteScanResult = result;
    _setState(result == null ? ViewState.Error : ViewState.Idle);
  }
}