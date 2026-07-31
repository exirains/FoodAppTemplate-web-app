import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/update_model.dart';

class UpdateRepository {
  // TODO: Replace with your actual GitHub raw URL for update.json
  static const String _updateUrl = 'https://raw.githubusercontent.com/username/sangak/main/update.json';

  Future<UpdateModel?> fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UpdateModel.fromJson(data);
      }
    } catch (e) {
      // Log error or handle gracefully
      print('Failed to fetch update info: $e');
    }
    return null;
  }
}
