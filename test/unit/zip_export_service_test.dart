// This code for testing ZipExportService archive generation, collision resolution, and file export helpers
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/storage/zip_export_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// This code for providing an isolated temporary directory for path provider platform
class FakePathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  // This code for storing mock temporary folder path
  final String tempPath;

  FakePathProviderPlatform(this.tempPath);

  @override
  Future<String?> getTemporaryPath() async => tempPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempPath;
}

void main() {
  // This code for initializing test environment before executing unit tests
  TestWidgetsFlutterBinding.ensureInitialized();

  // This code for grouping zip export service archive compression test cases
  group('ZipExportService Unit Tests', () {
    late Directory tempDir;
    late FakePathProviderPlatform fakePathProvider;

    setUp(() async {
      // This code for creating an isolated directory for test execution
      tempDir = await Directory.systemTemp.createTemp('zip_export_test_');
      fakePathProvider = FakePathProviderPlatform(tempDir.path);
      PathProviderPlatform.instance = fakePathProvider;
    });

    tearDown(() async {
      // This code for cleaning up test artifacts after each test run
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('createZipFromFiles packages multiple files into a valid zip archive', () async {
      // This code for creating sample files to compress
      final file1 = File('${tempDir.path}/doc1.txt');
      await file1.writeAsString('Hello World from Document 1');

      final file2 = File('${tempDir.path}/doc2.txt');
      await file2.writeAsString('Second document content with more bytes');

      final targetZip = File('${tempDir.path}/output_archive.zip');

      final List<double> reportedProgress = [];
      final result = await ZipExportService.createZipFromFiles(
        [file1, file2],
        targetZip,
        onProgress: (p) => reportedProgress.add(p),
      );

      // This code for verifying export result metrics
      expect(result.fileCount, equals(2));
      expect(result.totalBytes, greaterThan(0));
      expect(await targetZip.exists(), isTrue);
      expect(reportedProgress.isNotEmpty, isTrue);
      expect(reportedProgress.last, equals(1.0));

      // This code for validating zip file structure by decoding archive contents
      final bytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.length, equals(2));
      final names = archive.files.map((f) => f.name).toSet();
      expect(names, contains('doc1.txt'));
      expect(names, contains('doc2.txt'));
    });

    test('createZipFromFiles resolves duplicate filenames by appending counter suffix', () async {
      // This code for creating duplicate named files in separate subdirectories
      final subDir1 = Directory('${tempDir.path}/folder1')..createSync();
      final subDir2 = Directory('${tempDir.path}/folder2')..createSync();
      final subDir3 = Directory('${tempDir.path}/folder3')..createSync();

      final file1 = File('${subDir1.path}/photo.jpg')..writeAsBytesSync([1, 2, 3]);
      final file2 = File('${subDir2.path}/photo.jpg')..writeAsBytesSync([4, 5, 6]);
      final file3 = File('${subDir3.path}/photo.jpg')..writeAsBytesSync([7, 8, 9]);

      final targetZip = File('${tempDir.path}/duplicate_resolved.zip');
      final result = await ZipExportService.createZipFromFiles(
        [file1, file2, file3],
        targetZip,
      );

      // This code for verifying archive entries had unique filenames assigned
      expect(result.fileCount, equals(3));
      final bytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      final names = archive.files.map((f) => f.name).toList();

      expect(names, contains('photo.jpg'));
      expect(names, contains('photo_1.jpg'));
      expect(names, contains('photo_2.jpg'));
    });

    test('createZipFromFiles safely replaces existing target destination zip file', () async {
      // This code for testing destination overwrite behavior
      final targetZip = File('${tempDir.path}/overwrite_me.zip');
      await targetZip.writeAsString('old existing invalid data');

      final newFile = File('${tempDir.path}/fresh.txt')..writeAsStringSync('new data');
      final result = await ZipExportService.createZipFromFiles([newFile], targetZip);

      expect(result.fileCount, equals(1));
      expect(await targetZip.exists(), isTrue);

      final bytes = await targetZip.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.files.first.name, equals('fresh.txt'));
    });

    test('exportAndShareMediaItems returns null if items list is empty or files do not exist', () async {
      // This code for verifying early return when no valid files are provided
      final emptyResult = await ZipExportService.exportAndShareMediaItems([]);
      expect(emptyResult, isNull);

      final nonExistentItem = MediaItem(
        id: 'missing_1',
        mediaType: 'image',
        fileSize: 100,
        dateAdded: DateTime.now(),
        isFavorite: false,
        isTrashed: false,
        syncStatus: 'local',
        cloudState: 'LOCAL_ONLY',
        isPinnedOffline: false,
        filePath: '${tempDir.path}/does_not_exist_file.jpg',
      );

      final missingResult = await ZipExportService.exportAndShareMediaItems([nonExistentItem]);
      expect(missingResult, isNull);
    });

    test('exportAndShareMediaItems creates zip and respects customZipName with invokeShare false', () async {
      // This code for creating real local file matching MediaItem
      final validFile = File('${tempDir.path}/vacation.png')..writeAsBytesSync([10, 20, 30, 40]);
      final validItem = MediaItem(
        id: 'vacation_item',
        mediaType: 'image',
        fileSize: 4,
        dateAdded: DateTime.now(),
        isFavorite: true,
        isTrashed: false,
        syncStatus: 'synced',
        cloudState: 'SYNCED',
        isPinnedOffline: false,
        filePath: validFile.path,
      );

      final result = await ZipExportService.exportAndShareMediaItems(
        [validItem],
        customZipName: 'custom_vacation_export.zip',
        invokeShare: false,
      );

      // This code for verifying export result properties
      expect(result, isNotNull);
      expect(result!.fileCount, equals(1));
      expect(result.zipFile.path.endsWith('custom_vacation_export.zip'), isTrue);
      expect(await result.zipFile.exists(), isTrue);
    });
  });
}
