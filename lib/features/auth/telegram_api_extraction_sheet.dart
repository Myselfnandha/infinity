// This code for rendering modal WebView sheet to auto-extract Telegram API credentials
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/di/providers.dart';
import 'telegram_api_extractor_helper.dart';

/// Modal bottom sheet embedding an in-app WebView for automated extraction of
/// Telegram API credentials (api_id and api_hash) from my.telegram.org.
class TelegramApiExtractionSheet extends ConsumerStatefulWidget {
  const TelegramApiExtractionSheet({super.key});

  /// Displays the full-screen view and returns extracted credentials map when completed
  static Future<Map<String, dynamic>?> show(BuildContext context) {
    return Navigator.of(context, rootNavigator: true).push<Map<String, dynamic>>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => const TelegramApiExtractionSheet(),
      ),
    );
  }

  @override
  ConsumerState<TelegramApiExtractionSheet> createState() => _TelegramApiExtractionSheetState();
}

class _TelegramApiExtractionSheetState extends ConsumerState<TelegramApiExtractionSheet> {
  WebViewController? _webViewController;
  bool _isWebViewSupported = false;
  double _loadingProgress = 0.0;
  bool _hasExtracted = false;
  int? _extractedApiId;
  String? _extractedApiHash;
  String _currentStage = 'loading';
  String _statusMessage = 'Connecting to my.telegram.org...';
  Timer? _pollingTimer;

  // Manual fallback controllers in case user chooses to manually verify or paste
  final TextEditingController _manualIdController = TextEditingController();
  final TextEditingController _manualHashController = TextEditingController();
  bool _showManualFallback = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    try {
      final controller = WebViewController();
      controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      controller.setBackgroundColor(CupertinoColors.systemBackground);

      controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() => _loadingProgress = progress / 100.0);
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _statusMessage = 'Loading ${Uri.parse(url).path}...';
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _loadingProgress = 1.0;
                _statusMessage = 'Page loaded. Monitoring DOM for credentials...';
              });
              _triggerDomExtraction();
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _statusMessage = 'Network notice: ${error.description}';
              });
            }
          },
        ),
      );

      // Register the JavaScriptChannel for bidirectional communication
      controller.addJavaScriptChannel(
        'TelegramExtractor',
        onMessageReceived: (JavaScriptMessage message) {
          _processExtractedPayload(message.message);
        },
      );

      controller.loadRequest(Uri.parse(TelegramApiExtractorHelper.myTelegramOrgAuthUrl));
      _webViewController = controller;
      _isWebViewSupported = true;

      // Start periodic DOM inspection to catch live DOM changes without requiring full reloads
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (!_hasExtracted && mounted) {
          _triggerDomExtraction();
        }
      });
    } catch (_) {
      _isWebViewSupported = false;
      _showManualFallback = true;
      _statusMessage = 'WebView not available on this platform. Please enter credentials manually.';
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _manualIdController.dispose();
    _manualHashController.dispose();
    super.dispose();
  }

  /// Triggers the JavaScript DOM scanner inside the active WebView session
  Future<void> _triggerDomExtraction() async {
    if (_webViewController == null || _hasExtracted || !mounted) return;
    try {
      final rawResult = await _webViewController!.runJavaScriptReturningResult(
        TelegramApiExtractorHelper.extractionScript,
      );
      String resStr = rawResult.toString();
      // Unwrap potential JSON string encoding from Android WebView bridge
      if (resStr.startsWith('"') && resStr.endsWith('"')) {
        try {
          resStr = jsonDecode(resStr);
        } catch (_) {}
      }
      _processExtractedPayload(resStr);
    } catch (_) {
      // Ignore evaluation hiccups during page transitions
    }
  }

  /// Processes raw payload received from DOM inspection or JavaScriptChannel
  void _processExtractedPayload(String payloadString) async {
    if (_hasExtracted || !mounted) return;

    final parsed = TelegramApiExtractorHelper.parseExtractorMessage(payloadString);
    if (parsed == null) return;

    final String stage = parsed['stage']?.toString() ?? 'unknown';
    _updateStageUi(stage);

    final bool isComplete = parsed['isComplete'] == true;
    final int? apiId = parsed['apiId'] as int?;
    final String? apiHash = parsed['apiHash'] as String?;

    if (isComplete && apiId != null && apiHash != null) {
      _hasExtracted = true;
      _pollingTimer?.cancel();

      setState(() {
        _extractedApiId = apiId;
        _extractedApiHash = apiHash;
        _currentStage = 'extracted';
        _statusMessage = 'Credentials extracted! API ID: $apiId';
      });

      await _saveAndRestartTdlib(apiId, apiHash);
    }
  }

  /// Updates UI guidance text according to detected user flow stage on my.telegram.org
  void _updateStageUi(String stage) {
    if (!mounted || _hasExtracted) return;
    setState(() {
      _currentStage = stage;
      if (stage == 'waiting_code') {
        _statusMessage = 'Telegram sent a login code to your Telegram app. Enter it below.';
      } else if (stage == 'create_app') {
        _statusMessage = 'Application form detected. Tap "Create application" to finish.';
      } else if (stage == 'apps_page') {
        _statusMessage = 'Scanning application credentials...';
      } else if (stage == 'auth_page') {
        _statusMessage = 'Enter your phone number with country code.';
      }
    });
  }

  /// Persists credentials to AppPreferences, dismisses full-screen view cleanly, then restarts TDLib
  Future<void> _saveAndRestartTdlib(int apiId, String apiHash) async {
    try {
      final prefs = ref.read(preferencesProvider);
      await prefs.setTelegramApiId(apiId);
      await prefs.setTelegramApiHash(apiHash);

      // Dismiss route immediately before reinitializing TDLib to eliminate modal shuttering
      if (mounted) {
        Navigator.of(context).pop({
          'apiId': apiId,
          'apiHash': apiHash,
        });
      }

      // Smoothly restart TDLib client in the background with newly acquired API credentials
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.restartClient(apiId: apiId, apiHash: apiHash);
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to apply credentials: $e';
        });
      }
    }
  }

  /// Submits manual input fallback
  Future<void> _submitManual() async {
    final idText = _manualIdController.text.trim();
    final hashText = _manualHashController.text.trim();
    final parsedId = int.tryParse(idText);

    if (parsedId == null || parsedId <= 0) {
      setState(() => _statusMessage = 'Please enter a valid numeric API ID');
      return;
    }
    if (hashText.length != 32) {
      setState(() => _statusMessage = 'API Hash must be a 32-character hexadecimal string');
      return;
    }

    _hasExtracted = true;
    _pollingTimer?.cancel();
    await _saveAndRestartTdlib(parsedId, hashText);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Auto-Connect Telegram API'),
        leading: const Icon(
          CupertinoIcons.shield_lefthalf_fill,
          color: CupertinoColors.activeBlue,
          size: 20,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontSize: 15)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Live progress & extraction banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _hasExtracted
                  ? CupertinoColors.activeGreen.withValues(alpha: 0.15)
                  : CupertinoColors.systemGrey6.resolveFrom(context),
              child: Row(
                children: [
                  if (_hasExtracted)
                    const Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.activeGreen,
                      size: 20,
                    )
                  else if (_loadingProgress < 1.0)
                    const CupertinoActivityIndicator(radius: 8)
                  else
                    const Icon(
                      CupertinoIcons.sparkles,
                      color: CupertinoColors.activeBlue,
                      size: 20,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _hasExtracted ? FontWeight.w600 : FontWeight.normal,
                        color: _hasExtracted
                            ? CupertinoColors.activeGreen
                            : CupertinoColors.label.resolveFrom(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_currentStage != 'loading' && !_hasExtracted)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _currentStage.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Page loading linear indicator
            if (_loadingProgress > 0.0 && _loadingProgress < 1.0)
              SizedBox(
                height: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    children: [
                      Container(color: CupertinoColors.systemGrey5),
                      Container(
                        width: constraints.maxWidth * _loadingProgress.clamp(0.0, 1.0),
                        color: CupertinoColors.activeBlue,
                      ),
                    ],
                  ),
                ),
              ),

            // Main Webview content or manual entry fallback
            Expanded(
              child: _showManualFallback || !_isWebViewSupported
                  ? _buildManualFallbackView()
                  : Stack(
                      children: [
                        WebViewWidget(controller: _webViewController!),
                        if (_hasExtracted)
                          Container(
                            color: CupertinoColors.systemBackground.withValues(alpha: 0.85),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    color: CupertinoColors.activeGreen,
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Telegram API Connected!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'API ID: $_extractedApiId',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                  if (_extractedApiHash != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'API Hash: ${_extractedApiHash!.length >= 10 ? "${_extractedApiHash!.substring(0, 8)}..." : _extractedApiHash}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Bottom toolbar for manual re-scan, toggle manual paste, or refresh
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      setState(() => _showManualFallback = !_showManualFallback);
                    },
                    child: Text(
                      _showManualFallback ? 'Show Browser' : 'Manual Paste',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (!_showManualFallback && _isWebViewSupported)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          onPressed: () {
                            _webViewController?.reload();
                          },
                          child: const Icon(CupertinoIcons.refresh, size: 18),
                        ),
                        CupertinoButton.filled(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          onPressed: _hasExtracted ? null : _triggerDomExtraction,
                          child: const Text('Extract Now', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualFallbackView() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Telegram API Credentials',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Log in to https://my.telegram.org in any external browser, navigate to API Development Tools, and copy your credentials below:',
            style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel),
          ),
          const SizedBox(height: 16),
          CupertinoTextField(
            controller: _manualIdController,
            placeholder: 'API ID (e.g. 30662321)',
            keyboardType: TextInputType.number,
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _manualHashController,
            placeholder: 'API Hash (32-character hex)',
            padding: const EdgeInsets.all(12),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: _submitManual,
            child: const Text('Apply and Connect'),
          ),
        ],
      ),
    );
  }
}
