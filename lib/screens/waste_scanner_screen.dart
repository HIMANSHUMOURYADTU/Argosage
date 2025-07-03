import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/farm_provider.dart';
import '../utils/app_theme.dart';

class WasteScannerScreen extends StatefulWidget {
  const WasteScannerScreen({super.key});
  @override
  _WasteScannerScreenState createState() => _WasteScannerScreenState();
}

class _WasteScannerScreenState extends State<WasteScannerScreen> {
  XFile? _imageFile;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
      final provider = Provider.of<FarmProvider>(context, listen: false);

      // --- SIMPLIFIED LOGIC ---
      // No more platform checks! Just call the single, unified provider method.
      await provider.classifyWaste(pickedFile);
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
                ),
                child: _imageFile == null
                    ? const Center(
                        child: Text(
                          "Select an image of a waste item",
                          style: TextStyle(color: AppTheme.lightText, fontSize: 16),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        // This display logic remains, as it's for the UI widget itself.
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
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              // This Consumer widget works perfectly without any changes.
              Consumer<FarmProvider>(
                builder: (context, provider, child) {
                  if (provider.state == ViewState.Loading) {
                    return const CircularProgressIndicator();
                  }

                  if (provider.wasteScanResult != null) {
                    final result = provider.wasteScanResult!;
                    return Card(
                      key: ValueKey(result.caption),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "AI Waste Analysis",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: AppTheme.primary),
                            ),
                            const Divider(height: 20),
                            _buildResultRow("Detected Item:", result.caption, isBold: true),
                            _buildResultRow("Category:", result.category.toUpperCase(), isBold: true),
                            _buildResultRow("Recommended Bin:", result.binColor.toUpperCase(), isBold: true),
                            const SizedBox(height: 8),
                            _buildResultRow("Reason:", result.explanation),
                          ],
                        ),
                      ),
                    );
                  }

                  return const Text(
                    "Scan an item to see classification results.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.lightText),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // This helper widget remains unchanged.
  Widget _buildResultRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16),
          children: <TextSpan>[
            TextSpan(
              text: '$title ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.lightText),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }
}