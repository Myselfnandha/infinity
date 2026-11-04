// This code for testing EXIF metadata extraction and photo metadata container structures
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:infinity/core/media/exif_parser_service.dart';

// This code for executing ExifParserService and metadata unit tests
void main() {
  // This code for binding flutter test framework
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping ExifParserService tests
  group('ExifParserService & Media Processing Tests', () {
    late Directory tempDir;

    setUp(() {
      // This code for initializing temporary test directory
      tempDir = Directory.systemTemp.createTempSync('infinity_exif_test_');
    });

    tearDown(() {
      // This code for cleaning up temporary test directory
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    // This code for verifying non-existent file path handling
    test('Non-existent file returns default empty ExifMetadata gracefully', () async {
      // This code for verifying non-existent files are safely handled without throwing exceptions
      final meta = await ExifParserService.parseFile('/non/existent/image.jpg');
      expect(meta.cameraModel, isNull);
      expect(meta.aperture, isNull);
      expect(meta.latitude, isNull);
      expect(meta.longitude, isNull);
    });

    // This code for testing ExifMetadata container properties
    test('ExifMetadata model properties hold and retain values correctly', () {
      // This code for verifying ExifMetadata data container immutability and fields
      const meta = ExifMetadata(
        cameraModel: 'Sony A7 IV',
        lensModel: 'FE 24-70mm F2.8 GM II',
        aperture: 'f/2.8',
        shutterSpeed: '1/250s',
        iso: '100',
        focalLength: '35mm',
        latitude: 37.7749,
        longitude: -122.4194,
        dateTimeOriginal: '2026:10:15 14:32:00',
      );

      expect(meta.cameraModel, equals('Sony A7 IV'));
      expect(meta.lensModel, equals('FE 24-70mm F2.8 GM II'));
      expect(meta.aperture, equals('f/2.8'));
      expect(meta.shutterSpeed, equals('1/250s'));
      expect(meta.iso, equals('100'));
      expect(meta.focalLength, equals('35mm'));
      expect(meta.latitude, closeTo(37.77, 0.01));
      expect(meta.longitude, closeTo(-122.41, 0.01));
      expect(meta.dateTimeOriginal, equals('2026:10:15 14:32:00'));
    });

    // This code for testing partial ExifMetadata instantiation
    test('ExifMetadata handles partial and null fields with default constructor', () {
      // This code for verifying empty default constructor initialization
      const emptyMeta = ExifMetadata();
      expect(emptyMeta.cameraModel, isNull);
      expect(emptyMeta.lensModel, isNull);
      expect(emptyMeta.aperture, isNull);
      expect(emptyMeta.shutterSpeed, isNull);
      expect(emptyMeta.iso, isNull);
      expect(emptyMeta.focalLength, isNull);
      expect(emptyMeta.latitude, isNull);
      expect(emptyMeta.longitude, isNull);
      expect(emptyMeta.dateTimeOriginal, isNull);

      // This code for verifying southern and western hemisphere coordinates
      const southernMeta = ExifMetadata(
        latitude: -33.8688,
        longitude: 151.2093,
        cameraModel: 'Canon EOS R5',
      );
      expect(southernMeta.latitude, closeTo(-33.86, 0.01));
      expect(southernMeta.longitude, closeTo(151.20, 0.01));
      expect(southernMeta.cameraModel, equals('Canon EOS R5'));
    });

    // This code for verifying non-EXIF binary payload parsing
    test('Temporary file without EXIF headers returns empty ExifMetadata', () async {
      // This code for writing raw mock bytes and verifying parser resilience on non-EXIF payloads
      final tempFile = File('${tempDir.path}/sample.bin');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final meta = await ExifParserService.parseFile(tempFile.path);
      expect(meta.cameraModel, isNull);
      expect(meta.dateTimeOriginal, isNull);
    });

    // This code for verifying valid encoded JPEG without EXIF segment
    test('Valid encoded JPEG image file parses safely without exceptions', () async {
      // This code for creating valid JPEG using image package
      final image = img.Image(width: 16, height: 16);
      img.fill(image, color: img.ColorRgb8(128, 64, 32));
      final jpgBytes = img.encodeJpg(image);

      final tempFile = File('${tempDir.path}/test_image.jpg');
      await tempFile.writeAsBytes(jpgBytes);

      final meta = await ExifParserService.parseFile(tempFile.path);
      expect(meta.cameraModel, isNull);
      expect(meta.latitude, isNull);
      expect(meta.longitude, isNull);
    });

    // This code for testing corrupted JPEG header resilience
    test('Corrupted JPEG header returns empty ExifMetadata without throwing', () async {
      // This code for writing corrupt JPEG magic bytes
      final tempFile = File('${tempDir.path}/corrupt.jpg');
      await tempFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE1, 0x00, 0x04]);

      final meta = await ExifParserService.parseFile(tempFile.path);
      expect(meta.cameraModel, isNull);
      expect(meta.latitude, isNull);
    });
  });
}
