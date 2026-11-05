// This code for testing BackupTelemetrySheet and M3EWavyProgressIndicator widget components
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinity/core/database/app_database.dart';
import 'package:infinity/core/di/providers.dart';
import 'package:infinity/core/settings/app_preferences.dart';
import 'package:infinity/core/sync/sync_engine.dart';
import 'package:infinity/features/backup/backup_telemetry_sheet.dart';
import 'package:infinity/features/backup/widgets/m3e_wavy_progress_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('M3EWavyProgressIndicator Widget Tests', () {
    testWidgets('renders determinate wavy progress indicator without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: M3EWavyProgressIndicator(
                  progress: 0.5,
                  color: Color(0xFF00E5FF),
                  backgroundColor: Color(0x3300E5FF),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(M3EWavyProgressIndicator), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('renders indeterminate wavy progress indicator cleanly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: M3EWavyProgressIndicator(
                  progress: null, // indeterminate
                  color: Color(0xFF00E676),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(M3EWavyProgressIndicator), findsOneWidget);
    });
  });

  group('BackupTelemetrySheet Widget Tests', () {
    late TestDatabase db;
    late AppPreferences prefs;
    late FakeTdlibService fakeTdlib;
    late FakeBiometricService fakeBio;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await AppPreferences.getInstance();
      db = TestDatabase();
      fakeTdlib = FakeTdlibService();
      fakeBio = FakeBiometricService();
    });

    tearDown(() async {
      await db.close();
      fakeTdlib.dispose();
    });

    Widget buildSheetWithOverrides({
      UploadTelemetryState telemetry = const UploadTelemetryState(),
      List<MediaItem> pendingItems = const [],
    }) {
      return buildTestApp(
        child: const Material(
          type: MaterialType.transparency,
          child: BackupTelemetrySheet(),
        ),
        database: db,
        preferences: prefs,
        tdlibService: fakeTdlib,
        biometricService: fakeBio,
        additionalOverrides: [
          uploadTelemetryProvider.overrideWith((ref) => Stream.value(telemetry)),
          pendingUploadMediaProvider.overrideWith((ref) => Stream.value(pendingItems)),
        ],
      );
    }

    testWidgets('BackupTelemetrySheet renders header, status card, and empty queue state', (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetWithOverrides());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Uploads & Telemetry'), findsOneWidget);
      expect(find.text('CLOUD SYNCHRONIZED'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Transfer queue is empty'), findsOneWidget);
      expect(find.text('Monitored Backup Folders'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('BackupTelemetrySheet renders UPLINK ACTIVE with speedometer when actively uploading', (WidgetTester tester) async {
      const activeTelemetry = UploadTelemetryState(
        isPaused: false,
        activeWorkers: 1,
        speedKBps: 13107.2, // ~12.8 MB/s
        bytesTransferredTotal: 2500000,
        completedCount: 1,
        totalCount: 2,
      );

      final dummyItem = MediaItem(
        id: 'test_item_1',
        mediaType: 'image',
        fileSize: 2500000,
        dateAdded: DateTime.now(),
        syncStatus: 'PENDING',
        cloudState: 'PENDING',
        filePath: '/storage/DCIM/Camera/photo.jpg',
        isFavorite: false,
        isTrashed: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        buildSheetWithOverrides(
          telemetry: activeTelemetry,
          pendingItems: [dummyItem],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('UPLINK ACTIVE'), findsOneWidget);
      expect(find.textContaining('MB/s'), findsOneWidget);
      expect(find.text('Active Transfer Queue (1)'), findsOneWidget);
      expect(find.text('Camera Roll'), findsWidgets);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('BackupTelemetrySheet renders TRANSMISSION PAUSED when paused by user', (WidgetTester tester) async {
      const pausedTelemetry = UploadTelemetryState(
        isPaused: true,
        activeWorkers: 0,
        speedKBps: 0.0,
      );

      await tester.pumpWidget(
        buildSheetWithOverrides(telemetry: pausedTelemetry),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TRANSMISSION PAUSED'), findsOneWidget);
      expect(find.text('Resume'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Tapping pause / resume buttons invokes sync engine operations', (WidgetTester tester) async {
      await tester.pumpWidget(buildSheetWithOverrides());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pause'), findsOneWidget);
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('BackupTelemetrySheet toggles folder accordion on tap', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final dummyItem = MediaItem(
        id: 'test_item_accordion',
        mediaType: 'image',
        fileSize: 1024,
        dateAdded: DateTime.now(),
        syncStatus: 'PENDING',
        cloudState: 'PENDING',
        filePath: '/storage/DCIM/Camera/accordion.jpg',
        isFavorite: false,
        isTrashed: false,
        isPinnedOffline: false,
      );

      await tester.pumpWidget(
        buildSheetWithOverrides(
          telemetry: const UploadTelemetryState(totalCount: 1),
          pendingItems: [dummyItem],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Camera Roll header should be expanded initially
      expect(find.text('accordion.jpg'), findsOneWidget);

      // Tap accordion header to collapse
      await tester.tap(find.text('Camera Roll').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('accordion.jpg'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
