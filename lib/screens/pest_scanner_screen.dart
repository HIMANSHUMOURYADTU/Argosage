import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/farm_provider.dart';
import '../utils/app_theme.dart';

class PestScannerScreen extends StatefulWidget {
  const PestScannerScreen({super.key});
  @override
  _PestScannerScreenState createState() => _PestScannerScreenState();
}

class _PestScannerScreenState extends State<PestScannerScreen> {
  // We only need the XFile, no need for a separate Uint8List for web.
  XFile? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      // Get the provider
      final provider = Provider.of<FarmProvider>(context, listen: false);

      // --- SIMPLIFIED LOGIC ---
      // No more platform checks here! Just call the single unified method.
      await provider.scanPest(pickedFile);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: _imageFile == null
                    ? const Center(
                        child: Text(
                          "Select an image of a plant leaf",
                          style: TextStyle(color: AppTheme.lightText, fontSize: 16),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        // This check is for DISPLAY only.
                        // On web, XFile.path is a URL that Image.network can display.
                        child: kIsWeb
                            ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                            : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text("Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary.withOpacity(0.15),
                      foregroundColor: AppTheme.primary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              // The consumer part remains the same, as it just reacts to provider state
              Consumer<FarmProvider>(
                builder: (context, provider, child) {
                  if (provider.state == ViewState.Loading) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("AI is analyzing...",
                              style: TextStyle(color: AppTheme.lightText, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (Widget child, Animation<double> animation) =>
                        FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position:
                            Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero)
                                .animate(animation),
                        child: child,
                      ),
                    ),
                    child: provider.pestScanResult != null
                        ? _buildResultCard(provider.pestScanResult!.diagnosis,
                            provider.pestScanResult!.solution)
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  // _buildResultCard remains unchanged
  Widget _buildResultCard(String diagnosis, String solution) {
    // ... same as before
    final isHealthy = diagnosis.toLowerCase().contains("healthy");
    return Card(
      key: ValueKey(diagnosis),
      color: isHealthy
          ? AppTheme.primary.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isHealthy ? AppTheme.primary : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                "AI Analysis Result",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Text("Diagnosis:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(diagnosis, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Text("Recommended Solution:",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText.withOpacity(0.8))),
          const SizedBox(height: 4),
          Text(solution, style: const TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }
}