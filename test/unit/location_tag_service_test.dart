// This code for comprehensive unit testing of LocationTagService, GPS distance calculations, locality resolution, and proximity queries
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/media/location_tag_service.dart';

// This code for executing LocationTagService unit tests
void main() {
  // This code for grouping LocationTagService unit tests
  group('LocationTagService Unit Tests', () {
    // This code for testing calculateDistanceKm with identical coordinates
    test('calculateDistanceKm returns 0.0 for identical coordinates', () {
      // This code for calculating distance between same points
      final dist = LocationTagService.calculateDistanceKm(37.7749, -122.4194, 37.7749, -122.4194);
      expect(dist, equals(0.0));
    });

    // This code for testing calculateDistanceKm for known cities
    test('calculateDistanceKm accurately computes spherical distance between London and Paris', () {
      // This code for calculating distance between London (51.5074, -0.1278) and Paris (48.8566, 2.3522)
      final dist = LocationTagService.calculateDistanceKm(51.5074, -0.1278, 48.8566, 2.3522);
      expect(dist, greaterThan(330));
      expect(dist, lessThan(360));
    });

    // This code for testing antipodal coordinates clamping to avoid NaN
    test('calculateDistanceKm clamps antipodal coordinate domains to prevent NaN', () {
      // This code for calculating distance between North and South poles
      final dist = LocationTagService.calculateDistanceKm(90.0, 0.0, -90.0, 0.0);
      expect(dist.isNaN, isFalse);
      expect(dist.isInfinite, isFalse);
      expect(dist, closeTo(6371.0 * pi, 0.1));
    });

    // This code for testing resolveLocalityTag for known cities
    test('resolveLocalityTag resolves exact coordinates of world cities', () {
      // This code for resolving San Francisco coordinates
      final sf = LocationTagService.resolveLocalityTag(37.7749, -122.4194);
      expect(sf, equals('San Francisco, USA'));

      // This code for resolving Tokyo coordinates
      final tokyo = LocationTagService.resolveLocalityTag(35.6762, 139.6503);
      expect(tokyo, equals('Tokyo, Japan'));

      // This code for resolving London coordinates
      final london = LocationTagService.resolveLocalityTag(51.5074, -0.1278);
      expect(london, equals('London, UK'));
    });

    // This code for testing resolveLocalityTag with nearby coordinates within radius
    test('resolveLocalityTag matches nearby coordinates within detection radius', () {
      // This code for resolving coordinates 5km away from downtown San Francisco
      final nearSf = LocationTagService.resolveLocalityTag(37.7800, -122.4100);
      expect(nearSf, equals('San Francisco, USA'));
    });

    // This code for testing resolveLocalityTag returns null for remote points
    test('resolveLocalityTag returns null for remote coordinates far from known cities', () {
      // This code for testing coordinates in the middle of Null Island / Atlantic Ocean
      final ocean = LocationTagService.resolveLocalityTag(0.0, 0.0);
      expect(ocean, isNull);
    });

    // This code for testing custom maxRadiusKm threshold
    test('resolveLocalityTag respects custom maxRadiusKm limit', () {
      // Point ~40km away from San Francisco (e.g. San Jose border)
      // With default 50km radius it matches San Francisco
      final defaultMatch = LocationTagService.resolveLocalityTag(37.5, -122.3);
      expect(defaultMatch, equals('San Francisco, USA'));

      // With strict 5km max radius it should not match
      final strictMatch = LocationTagService.resolveLocalityTag(37.5, -122.3, maxRadiusKm: 5.0);
      expect(strictMatch, isNull);
    });

    // This code for testing filterByProximity with list of media items
    test('filterByProximity filters items based on target coordinate radius and skips nulls', () {
      // This code for creating media items with varied coordinates
      final now = DateTime.now();
      final itemSf = MediaItem(
        id: 'item_sf',
        filePath: '/storage/sf.jpg',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        latitude: 37.7749,
        longitude: -122.4194,
      );
      final itemTokyo = MediaItem(
        id: 'item_tokyo',
        filePath: '/storage/tokyo.jpg',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        latitude: 35.6762,
        longitude: 139.6503,
      );
      final itemNoGps = MediaItem(
        id: 'item_no_gps',
        filePath: '/storage/nogps.jpg',
        mediaType: 'image',
        fileSize: 1000,
        dateAdded: now,
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        latitude: null,
        longitude: null,
      );

      // This code for filtering items within 20km of downtown San Francisco
      final results = LocationTagService.filterByProximity(
        [itemSf, itemTokyo, itemNoGps],
        targetLat: 37.7749,
        targetLng: -122.4194,
        radiusKm: 20.0,
      );

      expect(results.length, equals(1));
      expect(results.first.id, equals('item_sf'));
    });
  });
}
