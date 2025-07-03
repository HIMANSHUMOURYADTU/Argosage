// lib/models/pest_scan_result.dart

class PestScanResult {
  final String diagnosis;
  final String solution;

  PestScanResult({required this.diagnosis, required this.solution});

  factory PestScanResult.fromString(String rawResult) {
    try {
      // The backend formats the string like: "Diagnosis: [Text].\nSolution: [Text]."
      final diagnosisPart = rawResult.split('\n')[0].replaceFirst('Diagnosis: ', '').trim();
      final solutionPart = rawResult.split('\n')[1].replaceFirst('Solution: ', '').trim();
      return PestScanResult(diagnosis: diagnosisPart, solution: solutionPart);
    } catch (e) {
      // Fallback if the string format is unexpected
      return PestScanResult(diagnosis: "Analysis Complete", solution: rawResult);
    }
  }
}