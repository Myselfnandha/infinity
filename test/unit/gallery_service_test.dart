// This code for testing GalleryService device media scanning, permissions, and database integration
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/storage/gallery_service.dart';
import 'package:photo_manager/photo_manager.dart';

// This code for providing an isolated in-memory database instance
class TestAppDatabase extends AppDatabase {
  TestAppDatabase() : super.forTesting(NativeDatabase.memory());
}

void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping GalleryService unit test scenarios
  group('GalleryService Unit Tests', () {
    late TestAppDatabase db;
    late GalleryService galleryService;

    const MethodChannel pmChannel = MethodChannel('com.fluttercandies/photo_manager');

    setUp(() {
      // This code for initializing in-memory database and service before each test
      db = TestAppDatabase();
      galleryService = GalleryService(db);
    });

    tearDown(() async {
      // This code for cleaning up database and platform mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, null);
      await db.close();
    });

    test('requestPermissions returns true when authorized', () async {
      // This code for simulating granted permission response from native plugin
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.authorized.index;
        }
        return null;
      });

      final hasAccess = await galleryService.requestPermissions();
      expect(hasAccess, isTrue);
    });

    test('requestPermissions returns true when limited access is granted', () async {
      // This code for simulating iOS limited photo library access
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.limited.index;
        }
        return null;
      });

      final hasAccess = await galleryService.requestPermissions();
      expect(hasAccess, isTrue);
    });

    test('requestPermissions returns false when denied', () async {
      // This code for simulating denied permission response from native plugin
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.denied.index;
        }
        return null;
      });

      final hasAccess = await galleryService.requestPermissions();
      expect(hasAccess, isFalse);
    });

    test('requestPermissions returns false when restricted or notDetermined', () async {
      // This code for verifying parental restrictions or unprompted permissions
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.restricted.index;
        }
        return null;
      });

      var hasAccess = await galleryService.requestPermissions();
      expect(hasAccess, isFalse);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.notDetermined.index;
        }
        return null;
      });

      hasAccess = await galleryService.requestPermissions();
      expect(hasAccess, isFalse);
    });

    test('scanDeviceMedia returns 0 when permission is denied without querying albums', () async {
      // This code for verifying immediate return when permission is not granted
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.denied.index;
        }
        return null;
      });

      final count = await galleryService.scanDeviceMedia();
      expect(count, equals(0));

      final allItems = await db.watchAllMedia().first;
      expect(allItems, isEmpty);
    });

    test('scanDeviceMedia returns 0 when album path list is empty', () async {
      // This code for verifying handling when device gallery contains no albums
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.authorized.index;
        }
        if (call.method == 'getAssetPathList') {
          return {'data': []};
        }
        return null;
      });

      final count = await galleryService.scanDeviceMedia();
      expect(count, equals(0));
    });

    test('scanDeviceMedia returns 0 when album contains no assets', () async {
      // This code for verifying handling when album is present but contains 0 assets
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(pmChannel, (MethodCall call) async {
        if (call.method == 'requestPermissionExtend') {
          return PermissionState.authorized.index;
        }
        if (call.method == 'getAssetPathList') {
          return {
            'data': [
              {
                'id': 'empty_album',
                'name': 'Recent',
                'assetCount': 0,
                'isAll': true,
                'albumType': 1,
                'darwinAssetCollectionType': 0,
                'darwinAssetCollectionSubtype': 0,
              }
            ]
          };
        }
        if (call.method == 'getAssetListPaged') {
          return {'data': []};
        }
        return null;
      });

      final count = await galleryService.scanDeviceMedia();
      expect(count, equals(0));
    });
  });
}
