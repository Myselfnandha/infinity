import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/providers.dart';
import '../../core/storage/gallery_service.dart';
import '../../core/telegram/tdlib_service.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  int _currentPage = 0;
  bool _isLoading = false;
  String? _authError;

  bool _backupCamera = true;
  bool _backupVideos = true;
  bool _backupScreenshots = true;
  bool _backupDownloads = false;

  bool _wifiOnly = true;
  bool _instantSync = true;
  bool _biometricEnabled = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendPhoneNumber(phone);
    } catch (e) {
      setState(() => _authError = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendAuthCode(code);
    } catch (e) {
      setState(() => _authError = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // This code for submitting 2FA password to TDLib
  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.send2FaPassword(password);
    } catch (e) {
      setState(() => _authError = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // This code for requesting QR code login fallback in onboarding
  Future<void> _requestQr() async {
    setState(() {
      _isLoading = true;
      _authError = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.requestQrCode();
    } catch (e) {
      setState(() => _authError = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestGalleryPermission() async {
    final state = await PhotoManager.requestPermissionExtend();
    if (state.isAuth || state.hasAccess) {
      _nextPage();
    }
  }

  Future<void> _requestNotificationPermission() async {
    await Permission.notification.request();
    _nextPage();
  }

  // This code for completing onboarding, saving user preferences, and initiating async media indexing
  Future<void> _finishOnboarding() async {
    // This code for capturing required providers before navigation to prevent unmounted ref errors
    final prefs = ref.read(preferencesProvider);
    final db = ref.read(databaseProvider);
    final sync = ref.read(syncEngineProvider);

    await prefs.setOnboardingCompleted(true);
    await prefs.setWifiOnly(_wifiOnly);
    await prefs.setInstantSync(_instantSync);
    await prefs.setBiometricLockEnabled(_biometricEnabled);

    final selectedFolders = <String>[];
    if (_backupCamera) selectedFolders.add('camera');
    if (_backupVideos) selectedFolders.add('videos');
    if (_backupScreenshots) selectedFolders.add('screenshots');
    if (_backupDownloads) selectedFolders.add('downloads');
    await prefs.setBackupFolderIds(selectedFolders);

    // This code for navigating to main gallery timeline immediately for fluid UX
    if (mounted) {
      context.go('/');
    }

    // This code for scanning device media and queueing to Telegram vault in background
    unawaited(() async {
      try {
        final galleryService = GalleryService(db);
        await galleryService.scanDeviceMedia(limit: 500);
        await sync.autoQueueUnsynced();
      } catch (_) {}
    }());
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).value ??
        ref.read(tdlibServiceProvider).currentAuthState;

    if (_currentPage == 1 && authState == TelegramAuthState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nextPage();
      });
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Welcome (${_currentPage + 1}/7)'),
      ),
      child: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (page) => setState(() => _currentPage = page),
          children: [
            _buildWelcomePage(),
            _buildAuthPage(authState),
            _buildMediaPermissionPage(),
            _buildNotificationPermissionPage(),
            _buildFolderSelectionPage(),
            _buildSyncPreferencesPage(),
            _buildSecurityPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.infinite,
            size: 80,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to Infinity',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your personal cloud photo & video storage powered by Telegram Supergroups. Enjoy limitless storage, original quality preservation, and smart on-demand syncing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 48),
          CupertinoButton.filled(
            onPressed: _nextPage,
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthPage(TelegramAuthState authState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.lock_shield,
            size: 64,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 16),
          const Text(
            'Telegram Connection',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in to connect your private Telegram vault supergroup.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
          ),
          const SizedBox(height: 24),
          if (_authError != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _authError!,
                style: const TextStyle(
                  color: CupertinoColors.destructiveRed,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (authState == TelegramAuthState.waitingForQrCode &&
              ref.watch(tdlibServiceProvider).qrCodeLink != null) ...[
            // This code for rendering interactive QR code pairing modal
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: ref.watch(tdlibServiceProvider).qrCodeLink!,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Scan this QR code with Telegram on another device, or tap below to link directly with Telegram on this phone.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: () async {
                final link = ref.read(tdlibServiceProvider).qrCodeLink;
                if (link != null) {
                  final uri = Uri.parse(link);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: const Text('Open in Telegram App'),
            ),
            const SizedBox(height: 12),
            // This code for switching back to phone number input from QR code display
            CupertinoButton(
              onPressed: () {
                setState(() => _authError = null);
                ref.read(tdlibServiceProvider).resetToPhoneNumber();
              },
              child: const Text('Use Phone Number Instead'),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              onPressed: _nextPage,
              child: const Text('Configure Later'),
            ),
          ] else if (authState == TelegramAuthState.waitingForCode) ...[
            CupertinoTextField(
              controller: _codeController,
              placeholder: 'Enter 5-digit code',
              keyboardType: TextInputType.number,
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _submitCode,
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Verify Code'),
            ),
          ] else if (authState == TelegramAuthState.waitingForPassword) ...[
            CupertinoTextField(
              controller: _passwordController,
              placeholder: 'Enter 2FA password',
              obscureText: true,
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _submitPassword,
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Submit Password'),
            ),
          ] else ...[
            CupertinoTextField(
              controller: _phoneController,
              placeholder: 'Phone (+1234567890)',
              keyboardType: TextInputType.phone,
              padding: const EdgeInsets.all(14),
            ),
            const SizedBox(height: 16),
            CupertinoButton.filled(
              onPressed: _isLoading ? null : _submitPhone,
              child: _isLoading
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Text('Send Verification Code'),
            ),
            const SizedBox(height: 12),
            // This code for requesting QR code login fallback option
            CupertinoButton(
              onPressed: _isLoading ? null : _requestQr,
              child: const Text('Log In via QR Code'),
            ),
            const SizedBox(height: 6),
            CupertinoButton(
              onPressed: _nextPage,
              child: const Text('Configure Later'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 72,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Photo & Video Access',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Infinity requires read access to your device gallery to automatically scan, display, and back up your memories to your Telegram Vault.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          CupertinoButton.filled(
            onPressed: _requestGalleryPermission,
            child: const Text('Grant Media Permission'),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: _nextPage,
            child: const Text('Skip for Now'),
          ),
        ],
      ),
    );
  }

  // This code for rendering the notification permission educational step
  Widget _buildNotificationPermissionPage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.bell_fill,
            size: 72,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Background Sync Alerts',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Notification permissions allow Infinity to display an active upload foreground service. This prevents Android from stopping your large photo and video uploads in the background.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 40),
          CupertinoButton.filled(
            onPressed: _requestNotificationPermission,
            child: const Text('Allow Notifications'),
          ),
          const SizedBox(height: 12),
          CupertinoButton(
            onPressed: _nextPage,
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderSelectionPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Backup Folders',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose which device folders should be monitored for automatic cloud backup.',
            style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildFolderCheckbox(
                  'Camera Roll',
                  'Main camera photos and videos',
                  _backupCamera,
                  (val) => setState(() => _backupCamera = val),
                ),
                _buildFolderCheckbox(
                  'Videos',
                  'Dedicated video captures',
                  _backupVideos,
                  (val) => setState(() => _backupVideos = val),
                ),
                _buildFolderCheckbox(
                  'Screenshots',
                  'Captured device screenshots',
                  _backupScreenshots,
                  (val) => setState(() => _backupScreenshots = val),
                ),
                _buildFolderCheckbox(
                  'Downloads',
                  'Saved web and messaging files',
                  _backupDownloads,
                  (val) => setState(() => _backupDownloads = val),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: _nextPage,
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: CupertinoButton.filled(
                  onPressed: _nextPage,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderCheckbox(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sync Preferences',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure how and when your media is uploaded.',
            style: TextStyle(color: CupertinoColors.secondaryLabel, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _buildFolderCheckbox(
            'Upload Over Wi-Fi Only',
            'Avoid using cellular data for large file transfers',
            _wifiOnly,
            (val) => setState(() => _wifiOnly = val),
          ),
          _buildFolderCheckbox(
            'Instant Sync on Capture',
            'Queue photos immediately when captured by camera',
            _instantSync,
            (val) => setState(() => _instantSync = val),
          ),
          const Spacer(),
          CupertinoButton.filled(
            onPressed: _nextPage,
            child: const Center(child: Text('Continue')),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityPage() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: 72,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Security & App Lock',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            'Protect your Infinity Vault with on-device biometrics (Face ID or Fingerprint) whenever the app is opened.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          _buildFolderCheckbox(
            'Enable Biometric Lock',
            'Require authentication to open vault',
            _biometricEnabled,
            (val) => setState(() => _biometricEnabled = val),
          ),
          const SizedBox(height: 40),
          CupertinoButton.filled(
            onPressed: _finishOnboarding,
            child: const Text('Complete Setup'),
          ),
        ],
      ),
    );
  }
}
