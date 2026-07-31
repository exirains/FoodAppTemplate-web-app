import 'dart:convert';
import 'package:http/http.dart' as http;
import 'update_model.dart';

class UpdateRepository {
  static const String _updateUrl = 'https://raw.githubusercontent.com/exirains/sangak-app/main/update.json';

  Future<UpdateModel?> fetchUpdateInfo() async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UpdateModel.fromJson(data);
      }
    } catch (_) {
      // Graceful failure
    }
    return null;
  }
}
