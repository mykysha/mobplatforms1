import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> readData(String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    if (!await file.exists()) {
      return 'File not found';
    }

    return await file.readAsString();
  } catch (e) {
    return 'Error reading file: $e';
  }
}

Future<String> writeData(String fileName, String data) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(data);
    return 'Data written successfully';
  } catch (e) {
    return 'Error writing file: $e';
  }
}
