import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:image_picker/image_picker.dart';

import '../models/dashboard_data.dart';
import '../models/mission.dart';
import '../models/pest_scan_result.dart';
import '../models/waste_scan_result.dart';

class ApiService {
  final String _baseUrl = 'http://127.0.0.1:8000'; // Use 10.0.2.2 on Android Emulator
  final Dio _dio = Dio();

  Future<DashboardData?> getDashboardData() async {
    // ... (no changes here)
    try {
      final response = await _dio.get('$_baseUrl/dashboard-data');
      return DashboardData.fromJson(response.data);
    } catch (e) {
      print("Error fetching dashboard data: $e");
      return null;
    }
  }

  Future<List<Mission>> getMissions() async {
    // ... (no changes here)
    try {
      final response = await _dio.get('$_baseUrl/missions');
      return (response.data as List).map((json) => Mission.fromJson(json)).toList();
    } catch (e) {
      print("Error fetching missions: $e");
      return [];
    }
  }

  Future<bool> completeMission(String missionId) async {
    // ... (no changes here)
    try {
      await _dio.post('$_baseUrl/complete-mission/$missionId');
      return true;
    } catch (e) {
      print("Error completing mission: $e");
      return false;
    }
  }

  /// UNIFIED: Scans a pest image. Works on both mobile/desktop and web.
  Future<PestScanResult?> scanPest(XFile imageFile) async {
    try {
      // Use imageFile.name for a cross-platform-safe filename.
      String fileName = imageFile.name;
      
      FormData formData;

      if (kIsWeb) {
        // On Web, we read the file's bytes and use MultipartFile.fromBytes
        Uint8List bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        // On mobile/desktop, we use the file's path and MultipartFile.fromFile
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
        });
      }
      
      final response = await _dio.post('$_baseUrl/scan-pest', data: formData);
      return PestScanResult.fromString(response.data['result']);
      
    } catch (e) {
      print("Error scanning pest: $e");
      return null;
    }
  }

  /// UNIFIED: Classifies a waste image. Works on both mobile/desktop and web.
  Future<WasteScanResult?> classifyWaste(XFile imageFile) async {
    try {
      String fileName = imageFile.name;
      
      FormData formData;

      if (kIsWeb) {
        // On Web, read bytes
        Uint8List bytes = await imageFile.readAsBytes();
        formData = FormData.fromMap({
          "file": MultipartFile.fromBytes(bytes, filename: fileName),
        });
      } else {
        // On mobile/desktop, use path
        formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(imageFile.path, filename: fileName),
        });
      }
      
      final response = await _dio.post('$_baseUrl/classify-waste', data: formData);
      return WasteScanResult.fromJson(response.data);

    } catch (e) {
      print("Error classifying waste: $e");
      return null;
    }
  }

  /// Chatbot
  Future<String> askEcoBot(String query) async {
    // ... (no changes here)
    try {
      final response = await _dio.post('$_baseUrl/ask-ecobot', data: {'query': query});
      return response.data['response'] ?? "I'm sorry, I couldn't get a response.";
    } catch (e) {
      print("Error calling EcoBot API: $e");
      return "Sorry, I couldn't connect to the bot.";
    }
  }
}