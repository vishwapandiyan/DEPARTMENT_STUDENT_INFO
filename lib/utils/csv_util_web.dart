import 'dart:convert';
import 'dart:html' as html;

/// Web-specific CSV download implementation
Future<void> downloadCsv(String csvData, String fileName) async {
  final bytes = utf8.encode(csvData);
  final blob = html.Blob([bytes], 'text/csv');
  final url = html.Url.createObjectUrlFromBlob(blob);
  
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  
  html.Url.revokeObjectUrl(url);
}
