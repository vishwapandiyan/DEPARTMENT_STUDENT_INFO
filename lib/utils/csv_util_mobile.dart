import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Mobile-specific CSV download implementation
Future<void> downloadCsv(String csvData, String fileName) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$fileName');
  await file.writeAsString(csvData);
  
  // On mobile, the file is saved to the app's documents directory
  // You might want to use share_plus package to share the file
  print('CSV file saved to: ${file.path}');
}
