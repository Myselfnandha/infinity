import 'package:flutter/cupertino.dart';
import '../../core/database/app_database.dart';
import '../../core/media/exif_parser_service.dart';
import '../../core/media/location_tag_service.dart';

class ExifInfoSheet extends StatefulWidget {
  final MediaItem item;

  const ExifInfoSheet({super.key, required this.item});

  @override
  State<ExifInfoSheet> createState() => _ExifInfoSheetState();
}

class _ExifInfoSheetState extends State<ExifInfoSheet> {
  ExifMetadata? _metadata;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExif();
  }

  Future<void> _loadExif() async {
    if (widget.item.filePath != null) {
      final data = await ExifParserService.parseFile(widget.item.filePath!);
      if (mounted) {
        setState(() {
          _metadata = data;
          _loading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Details & EXIF',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRow('Dimensions', '${widget.item.width ?? 0} × ${widget.item.height ?? 0} px'),
            _buildRow('File Size', '${(widget.item.fileSize / (1024 * 1024)).toStringAsFixed(2)} MB'),
            _buildRow('Sync Status', widget.item.syncStatus.toUpperCase()),
            if (widget.item.locationName != null)
              _buildRow('Location', widget.item.locationName!),
            // This code for hiding internal perceptual hash from end-user EXIF sheet display
            if (widget.item.telegramMessageId != null)
              _buildRow('Telegram Message ID', widget.item.telegramMessageId.toString()),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (_metadata != null) ...[
              if (_metadata!.cameraModel != null)
                _buildRow('Camera', _metadata!.cameraModel!),
              if (_metadata!.lensModel != null)
                _buildRow('Lens', _metadata!.lensModel!),
              if (_metadata!.aperture != null)
                _buildRow('Aperture', _metadata!.aperture!),
              if (_metadata!.shutterSpeed != null)
                _buildRow('Shutter Speed', _metadata!.shutterSpeed!),
              if (_metadata!.iso != null)
                _buildRow('ISO', _metadata!.iso!),
              if (_metadata!.focalLength != null)
                _buildRow('Focal Length', _metadata!.focalLength!),
              if (_metadata!.latitude != null && _metadata!.longitude != null) ...[
                if (widget.item.locationName == null &&
                    LocationTagService.resolveLocalityTag(
                            _metadata!.latitude!, _metadata!.longitude!) !=
                        null)
                  _buildRow(
                    'Location',
                    LocationTagService.resolveLocalityTag(
                        _metadata!.latitude!, _metadata!.longitude!)!,
                  ),
                _buildRow(
                  'Location Coordinates',
                  '${_metadata!.latitude!.toStringAsFixed(4)}, ${_metadata!.longitude!.toStringAsFixed(4)}',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

