import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AddressLocation {
  final String? neighborhood;
  final String? street;
  final String? district;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? buildingNumber;
  final String? formattedAddress;

  const AddressLocation({
    this.neighborhood,
    this.street,
    this.district,
    this.city,
    this.postalCode,
    this.country,
    this.buildingNumber,
    this.formattedAddress,
  });

  factory AddressLocation.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    
    return AddressLocation(
      neighborhood: properties['suburb'] ?? properties['neighborhood'] ?? properties['quarter'] ?? properties['district'],
      street: properties['street'],
      district: properties['city_district'] ?? properties['county'] ?? properties['district'] ?? properties['suburb'] ?? properties['state_district'],
      city: properties['city'] ?? properties['state'] ?? properties['province'],
      postalCode: properties['postcode'],
      country: properties['country'],
      buildingNumber: properties['housenumber'],
      formattedAddress: properties['formatted'],
    );
  }
}

class GeoapifyService {
  static final String? _apiKey = dotenv.env['GEOAPIFY_API_KEY'];
  static const String _baseUrl = 'https://api.geoapify.com/v1/geocode/reverse';

  /// Performs reverse geocoding to get structured address from coordinates
  Future<AddressLocation?> reverseGeocode(double lat, double lon) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Geoapify API Key is missing');
      return null;
    }

    final url = Uri.parse('$_baseUrl?lat=$lat&lon=$lon&apiKey=$_apiKey');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List?;
        
        if (features != null && features.isNotEmpty) {
          return AddressLocation.fromJson(features[0]);
        }
      } else {
        debugPrint('Geoapify Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Geoapify Exception: $e');
    }
    
    return null;
  }
}
