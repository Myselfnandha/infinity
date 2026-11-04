// This code for resolving GPS coordinates to locality tags and performing proximity queries
import 'dart:math';
import '../database/app_database.dart';

// This code for representing a geographical place with known coordinates
class KnownLocality {
  // This code for the human-readable display name of the locality
  final String name;

  // This code for latitude in decimal degrees
  final double latitude;

  // This code for longitude in decimal degrees
  final double longitude;

  // This code for detection radius around coordinates in kilometers
  final double radiusKm;

  const KnownLocality({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 50.0,
  });
}

// This code for providing coordinate distance calculations and locality tag mapping
class LocationTagService {
  // Earth mean spherical radius in kilometers
  static const double _earthRadiusKm = 6371.0;

  // This code for built-in offline lookup table of major world localities
  static const List<KnownLocality> knownLocalities = [
    KnownLocality(name: 'San Francisco, USA', latitude: 37.7749, longitude: -122.4194),
    KnownLocality(name: 'New York, USA', latitude: 40.7128, longitude: -74.0060),
    KnownLocality(name: 'London, UK', latitude: 51.5074, longitude: -0.1278),
    KnownLocality(name: 'Paris, France', latitude: 48.8566, longitude: 2.3522),
    KnownLocality(name: 'Tokyo, Japan', latitude: 35.6762, longitude: 139.6503),
    KnownLocality(name: 'Berlin, Germany', latitude: 52.5200, longitude: 13.4050),
    KnownLocality(name: 'Sydney, Australia', latitude: -33.8688, longitude: 151.2093),
    KnownLocality(name: 'Singapore', latitude: 1.3521, longitude: 103.8198),
    KnownLocality(name: 'Mumbai, India', latitude: 19.0760, longitude: 72.8777),
    KnownLocality(name: 'Dubai, UAE', latitude: 25.2048, longitude: 55.2708),
    KnownLocality(name: 'Toronto, Canada', latitude: 43.6532, longitude: -79.3832),
    KnownLocality(name: 'Los Angeles, USA', latitude: 34.0522, longitude: -118.2437),
    KnownLocality(name: 'Rome, Italy', latitude: 41.9028, longitude: 12.4964),
    KnownLocality(name: 'Cairo, Egypt', latitude: 30.0444, longitude: 31.2357),
    KnownLocality(name: 'Beijing, China', latitude: 39.9042, longitude: 116.4074),
    KnownLocality(name: 'Seoul, South Korea', latitude: 37.5665, longitude: 126.9780),
    KnownLocality(name: 'Rio de Janeiro, Brazil', latitude: -22.9068, longitude: -43.1729),
  ];

  // This code for calculating Haversine spherical distance between two coordinates in km
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    // this code for clamping a to valid domain [0.0, 1.0] to prevent antipodal float overflow NaN
    final aClamped = a.clamp(0.0, 1.0);
    final c = 2 * atan2(sqrt(aClamped), sqrt(1.0 - aClamped));
    return _earthRadiusKm * c;
  }

  // This code for converting angular degrees to radians
  static double _degreesToRadians(double degrees) => degrees * pi / 180.0;

  // This code for mapping GPS coordinates to the nearest offline locality tag
  static String? resolveLocalityTag(
    double latitude,
    double longitude, {
    double maxRadiusKm = 50.0,
  }) {
    KnownLocality? closest;
    double minDistance = double.infinity;

    for (final loc in knownLocalities) {
      final dist = calculateDistanceKm(latitude, longitude, loc.latitude, loc.longitude);
      final allowedRadius = min(loc.radiusKm, maxRadiusKm);
      if (dist <= allowedRadius && dist < minDistance) {
        minDistance = dist;
        closest = loc;
      }
    }

    return closest?.name;
  }

  // This code for filtering media items within a specified radius of target coordinates
  static List<MediaItem> filterByProximity(
    List<MediaItem> items, {
    required double targetLat,
    required double targetLng,
    required double radiusKm,
  }) {
    return items.where((item) {
      if (item.latitude == null || item.longitude == null) return false;
      final dist = calculateDistanceKm(
        targetLat,
        targetLng,
        item.latitude!,
        item.longitude!,
      );
      return dist <= radiusKm;
    }).toList();
  }
}
