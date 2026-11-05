// This code for compressing multi-selected vault items into a zip bundle and sharing via system sheet
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

// This code for encapsulating the result of a zip export operation
class ZipExportResult {
  // This code for the generated zip archive file
  final File zipFile;

  // This code for the number of files included in the zip archive
  final int fileCount;

  // This code for the total size of the zip archive in bytes
  final int totalBytes;

  const ZipExportResult({
    required this.zipFile,
    required this.fileCount,
    required this.totalBytes,
  });
}

// This code for batch exporting media items into zipped archives
class ZipExportService {
  // This code for creating a zip bundle from media items and presenting the native share sheet
  static Future<ZipExportResult?> exportAndShareMediaItems(
    List<MediaItem> items, {
    String? customZipName,
    Function(double progress)? onProgress,
    bool invokeShare = true,
  }) async {
    final validFiles = <File>[];
    for (final item in items) {
      if (item.filePath != null) {
        final f = File(item.filePath!);
        if (await f.exists()) {
          validFiles.add(f);
        }
      }
    }

    if (validFiles.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFileName = customZipName ?? 'infinity_vault_export_$timestamp.zip';
    final zipFile = File(p.join(tempDir.path, zipFileName));

    final result = await createZipFromFiles(
      validFiles,
      zipFile,
      onProgress: onProgress,
    );

    if (invokeShare) {
      // This code for triggering native system share sheet (AirDrop, Nearby Share, Telegram, email)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(zipFile.path)],
          subject: 'Infinity Vault Export',
          text: 'Exported ${result.fileCount} items from Infinity Vault',
        ),
      );
    }

    return result;
  }

  // This code for packing a collection of files into a target zip file with duplicate filename resolution
  static Future<ZipExportResult> createZipFromFiles(
    List<File> files,
    File destinationZip, {
    Function(double progress)? onProgress,
  }) async {
    if (await destinationZip.exists()) {
      await destinationZip.delete();
    }

    final encoder = ZipFileEncoder();
    encoder.create(destinationZip.path);

    final Set<String> usedNames = {};
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final originalName = p.basename(file.path);
      String targetName = originalName;
      int counter = 1;

      while (usedNames.contains(targetName.toLowerCase())) {
        final dotIdx = originalName.lastIndexOf('.');
        if (dotIdx != -1) {
          final base = originalName.substring(0, dotIdx);
          final ext = originalName.substring(dotIdx);
          targetName = '${base}_$counter$ext';
        } else {
          targetName = '${originalName}_$counter';
        }
        counter++;
      }

      usedNames.add(targetName.toLowerCase());
      await encoder.addFile(file, targetName);

      if (onProgress != null) {
        onProgress((i + 1) / files.length);
      }
    }

    await encoder.close();

    final bytes = await destinationZip.length();
    return ZipExportResult(
      zipFile: destinationZip,
      fileCount: files.length,
      totalBytes: bytes,
    );
  }
}
