// This code for testing EXIF metadata extraction and cloud media cache management policies
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/media/exif_parser_service.dart';

void main() {
  group('ExifParserService & Media Processing Tests', () {
    test('Non-existent file returns default empty ExifMetadata gracefully', () async {
      // This code for verifying non-existent files are safely handled without throwing exceptions
      final meta = await ExifParserService.parseFile('/non/existent/image.jpg');
      expect(meta.cameraModel, isNull);
      expect(meta.aperture, isNull);
      expect(meta.latitude, isNull);
      expect(meta.longitude, isNull);
    });

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
    });

    test('Temporary file without EXIF headers returns empty ExifMetadata', () async {
      // This code for writing raw mock bytes and verifying parser resilience on non-EXIF payloads
      final tempDir = Directory.systemTemp.createTempSync('infinity_test');
      final tempFile = File('${tempDir.path}/sample.bin');
      await tempFile.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      final meta = await ExifParserService.parseFile(tempFile.path);
      expect(meta.cameraModel, isNull);
      expect(meta.dateTimeOriginal, isNull);

      tempDir.deleteSync(recursive: true);
    });
  });
}

