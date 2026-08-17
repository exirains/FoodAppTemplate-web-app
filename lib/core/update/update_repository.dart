import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'update_model.dart';

class UpdateRepository {
  static const String _updateUrl = 'https://raw.githubusercontent.com/exirains/sangak-app/main/update.json';

  Future<UpdateModel?> fetchUpdateInfo() async {
    try {
      // Add a timestamp to bypass raw.githubusercontent.com cache (typically 5 mins)
      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final url = '$_updateUrl?t=$cacheBuster';
      
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UpdateModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
    return null;
  }
}
