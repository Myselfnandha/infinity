// This code for parsing EXIF photo metadata including camera model, lens, exposure, and GPS coordinates
import 'dart:io';
import 'package:exif/exif.dart';

// This code for holding parsed EXIF camera metadata
class ExifMetadata {
  final String? cameraModel;
  final String? lensModel;
  final String? aperture;
  final String? shutterSpeed;
  final String? iso;
  final String? focalLength;
  final double? latitude;
  final double? longitude;
  final String? dateTimeOriginal;

  const ExifMetadata({
    this.cameraModel,
    this.lensModel,
    this.aperture,
    this.shutterSpeed,
    this.iso,
    this.focalLength,
    this.latitude,
    this.longitude,
    this.dateTimeOriginal,
  });
}

// This code for reading and extracting EXIF tags from on-device media files
class ExifParserService {
  // This code for extracting camera parameters, lens settings, and GPS geolocation from photo bytes
  static Future<ExifMetadata> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ExifMetadata();
    }

    try {
      final bytes = await file.readAsBytes();
      final data = await readExifFromBytes(bytes);

      if (data.isEmpty) {
        return const ExifMetadata();
      }

      final cameraMake = data['Image Make']?.printable;
      final cameraModel = data['Image Model']?.printable;
      final fullCamera = cameraMake != null && cameraModel != null
          ? '$cameraMake $cameraModel'
          : cameraModel ?? cameraMake;

      final aperture = data['EXIF FNumber']?.printable;
      final shutter = data['EXIF ExposureTime']?.printable;
      final iso = data['EXIF ISOSpeedRatings']?.printable;
      final focal = data['EXIF FocalLength']?.printable;
      final lens = data['EXIF LensModel']?.printable;
      final date = data['EXIF DateTimeOriginal']?.printable;

      double? lat;
      double? lng;

      final gpsLat = data['GPS GPSLatitude'];
      final gpsLatRef = data['GPS GPSLatitudeRef']?.printable;
      final gpsLng = data['GPS GPSLongitude'];
      final gpsLngRef = data['GPS GPSLongitudeRef']?.printable;

      if (gpsLat != null && gpsLng != null) {
        lat = _convertToDegree(gpsLat);
        if (gpsLatRef == 'S' && lat != null) lat = -lat;

        lng = _convertToDegree(gpsLng);
        if (gpsLngRef == 'W' && lng != null) lng = -lng;
      }

      return ExifMetadata(
        cameraModel: fullCamera,
        lensModel: lens,
        aperture: aperture != null ? 'f/$aperture' : null,
        shutterSpeed: shutter != null ? '${shutter}s' : null,
        iso: iso != null ? 'ISO $iso' : null,
        focalLength: focal != null ? '${focal}mm' : null,
        latitude: lat,
        longitude: lng,
        dateTimeOriginal: date,
      );
    } catch (_) {
      return const ExifMetadata();
    }
  }

  static double? _convertToDegree(IfdTag tag) {
    final values = tag.values.toList();
    if (values.length >= 3) {
      final d = values[0] is Ratio ? (values[0] as Ratio).toDouble() : 0.0;
      final m = values[1] is Ratio ? (values[1] as Ratio).toDouble() : 0.0;
      final s = values[2] is Ratio ? (values[2] as Ratio).toDouble() : 0.0;
      return d + (m / 60.0) + (s / 3600.0);
    }
    return null;
  }
}
