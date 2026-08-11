import 'package:geolocator/geolocator.dart';
import '../core/location/geoapify_service.dart';

class LocationService {
  final _geoapify = GeoapifyService();

  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('locationServiceDisabled');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('locationPermissionDenied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('locationPermissionPermanentlyDenied');
    }

    return await Geolocator.getCurrentPosition();
  }

  /// Gets structured address data from coordinates using Geoapify
  Future<AddressLocation?> getAddressFromLatLng(double latitude, double longitude) async {
    return await _geoapify.reverseGeocode(latitude, longitude);
  }
}
