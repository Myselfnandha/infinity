// This code for managing Telegram Vault supergroup account status, pairing, and live authentication
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di/providers.dart';
import '../../core/telegram/tdlib_service.dart';
import '../auth/telegram_api_extraction_sheet.dart';

// This code for rendering the interactive Telegram Vault account details and authentication sub-page
class VaultAccountScreen extends ConsumerStatefulWidget {
  const VaultAccountScreen({super.key});

  @override
  ConsumerState<VaultAccountScreen> createState() => _VaultAccountScreenState();
}

class _VaultAccountScreenState extends ConsumerState<VaultAccountScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // This code for custom Telegram API credentials configuration
  final TextEditingController _apiIdController = TextEditingController();
  final TextEditingController _apiHashController = TextEditingController();
  bool _showCustomApi = false;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(preferencesProvider);
      final defaultId = TdlibService.defaultApiId;
      final defaultHash = TdlibService.defaultApiHash;

      _apiIdController.text = (prefs.telegramApiId ?? defaultId).toString();
      _apiHashController.text = prefs.telegramApiHash ?? defaultHash;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _apiIdController.dispose();
    _apiHashController.dispose();
    super.dispose();
  }

  // Applies user configured Telegram API credentials before initiating authentication
  Future<void> _applyCustomCredentialsIfAny() async {
    final prefs = ref.read(preferencesProvider);
    final idText = _apiIdController.text.trim();
    final hashText = _apiHashController.text.trim();
    int? parsedId;
    if (idText.isNotEmpty) {
      parsedId = int.tryParse(idText);
      if (parsedId != null) await prefs.setTelegramApiId(parsedId);
    }
    if (hashText.isNotEmpty) {
      await prefs.setTelegramApiHash(hashText);
    }

    final tdlib = ref.read(tdlibServiceProvider);
    if (parsedId != null && hashText.isNotEmpty) {
      if (tdlib.activeApiId != parsedId || tdlib.activeApiHash != hashText) {
        await tdlib.restartClient(apiId: parsedId, apiHash: hashText);
      }
    }
  }

  // This code for submitting phone number to initiate TDLib authentication
  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter a valid phone number');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _applyCustomCredentialsIfAny();
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendPhoneNumber(phone);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // This code for verifying Telegram 5-digit login code
  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _errorMessage = 'Please enter the verification code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendAuthCode(code);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // This code for verifying Telegram 2FA cloud password
  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your 2FA password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.send2FaPassword(password);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // This code for requesting QR code pairing link from TDLib
  Future<void> _requestQrCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.requestQrCode(useOfficialApiFallback: true);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // This code for disconnecting active Telegram session
  Future<void> _disconnectVault() async {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Disconnect Telegram Vault?'),
        message: const Text('This will unlink your private Infinity Vault supergroup on this device.'),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              final tdlib = ref.read(tdlibServiceProvider);
              await tdlib.logOut();
            },
            child: const Text('Disconnect Vault'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tdlib = ref.watch(tdlibServiceProvider);
    final authState = ref.watch(authStateProvider).value ?? tdlib.currentAuthState;
    final isConnected = tdlib.vaultChatId != null;

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        previousPageTitle: 'Settings',
        middle: Text('Vault Account'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // This code for rendering status summary card
            Container(
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Vault Supergroup Status'),
                        Text(
                          isConnected ? 'Connected' : 'Action Required',
                          style: TextStyle(
                            color: isConnected
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemOrange,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Telegram Chat ID'),
                        Text(
                          tdlib.vaultChatId?.toString() ?? 'Not Connected',
                          style: const TextStyle(color: CupertinoColors.secondaryLabel),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Connected Account'),
                        Text(
                          tdlib.authPhoneNumber ?? (isConnected ? 'Active Session' : 'None'),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Forum Topics Mode'),
                        Text(
                          isConnected ? 'Active (5 Topics)' : 'Standby',
                          style: TextStyle(
                            color: isConnected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.secondaryLabel,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // This code for showing error banner if present
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.exclamationmark_circle,
                            color: CupertinoColors.destructiveRed, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: CupertinoColors.activeGreen,
                          onPressed: () {
                            setState(() {
                              _showCustomApi = true;
                              _apiIdController.text = TdlibService.officialApiId.toString();
                              _apiHashController.text = TdlibService.officialApiHash;
                              _errorMessage = null;
                            });
                          },
                          child: const Text('Official API (2496)', style: TextStyle(fontSize: 11, color: CupertinoColors.white)),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          color: CupertinoColors.activeBlue,
                          onPressed: () {
                            setState(() {
                              _showCustomApi = true;
                              _apiIdController.text = TdlibService.defaultApiId.toString();
                              _apiHashController.text = TdlibService.defaultApiHash;
                              _errorMessage = null;
                            });
                          },
                          child: const Text('Workspace API (30662321)', style: TextStyle(fontSize: 11, color: CupertinoColors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // This code for rendering authentication workflow when vault is not yet connected
            if (!isConnected) ...[
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'CONNECT TELEGRAM VAULT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // This code for rendering QR code pairing view
                    if (authState == TelegramAuthState.waitingForQrCode &&
                        tdlib.qrCodeLink != null) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: QrImageView(
                            data: tdlib.qrCodeLink!,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Scan this QR code with Telegram on another device, or tap below to open Telegram directly on this phone.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        onPressed: () async {
                          final link = tdlib.qrCodeLink;
                          if (link != null) {
                            final uri = Uri.parse(link);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        child: const Text('Open in Telegram App'),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        onPressed: () {
                          setState(() => _errorMessage = null);
                          tdlib.initialize();
                        },
                        child: const Text('Use Phone Number Instead'),
                      ),
                    ] else if (authState == TelegramAuthState.waitingForCode) ...[
                      // This code for entering 5-digit Telegram SMS or in-app verification code
                      CupertinoTextField(
                        controller: _codeController,
                        placeholder: 'Enter 5-digit verification code',
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.all(14),
                      ),
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        onPressed: _isLoading ? null : _submitCode,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Verify Code'),
                      ),
                    ] else if (authState == TelegramAuthState.waitingForPassword) ...[
                      // This code for entering Telegram 2FA cloud password
                      CupertinoTextField(
                        controller: _passwordController,
                        placeholder: 'Enter 2FA cloud password',
                        obscureText: true,
                        padding: const EdgeInsets.all(14),
                      ),
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        onPressed: _isLoading ? null : _submitPassword,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Verify Password'),
                      ),
                    ] else ...[
                      // This code for entering phone number
                      CupertinoTextField(
                        controller: _phoneController,
                        placeholder: 'Phone number (e.g. +91 9876543210)',
                        keyboardType: TextInputType.phone,
                        padding: const EdgeInsets.all(14),
                      ),
                      const SizedBox(height: 14),
                      CupertinoButton.filled(
                        onPressed: _isLoading ? null : _submitPhone,
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white)
                            : const Text('Send Verification Code'),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        onPressed: _isLoading ? null : _requestQrCode,
                        child: const Text('Log In via QR Code'),
                      ),
                      const SizedBox(height: 10),
                      // This code for launching 1-tap automated browser modal extraction for Telegram API credentials
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                        onPressed: () async {
                          final result = await TelegramApiExtractionSheet.show(context);
                          if (result != null && mounted) {
                            final int? id = result['apiId'] as int?;
                            final String? hash = result['apiHash'] as String?;
                            if (id != null && hash != null) {
                              setState(() {
                                _apiIdController.text = id.toString();
                                _apiHashController.text = hash;
                                _showCustomApi = true;
                              });
                            }
                          }
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.compass, size: 18, color: CupertinoColors.activeBlue),
                            SizedBox(width: 8),
                            Text(
                              'Auto-Connect Telegram API (Browser)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // This code for toggling custom Telegram API credentials input
                      CupertinoButton(
                        onPressed: () => setState(() => _showCustomApi = !_showCustomApi),
                        child: Text(
                          _showCustomApi ? 'Hide API Configuration' : 'Custom Telegram API Credentials (Optional)',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_showCustomApi) ...[
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _apiIdController,
                          placeholder: 'Telegram API ID (from my.telegram.org)',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: _apiHashController,
                          placeholder: 'Telegram API Hash (hex string)',
                          padding: const EdgeInsets.all(12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              onPressed: () {
                                _apiIdController.text = '6';
                                _apiHashController.text = 'eb06d4abfb49dc3eeb1aeb9890c81e47';
                              },
                              child: const Text('Telegram Android (6)', style: TextStyle(fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              onPressed: () {
                                _apiIdController.text = '30662321';
                                _apiHashController.text = 'cf007e0155c41fd1aa9b114b592377e0';
                              },
                              child: const Text('Workspace API (30662321)', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              // This code for showing connected forum topics breakdown
              Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6.resolveFrom(context),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CONFIGURED TOPICS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTopicRow('Photos', CupertinoIcons.photo, CupertinoColors.activeBlue),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    _buildTopicRow('Videos', CupertinoIcons.videocam, CupertinoColors.systemPurple),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    _buildTopicRow('Screenshots', CupertinoIcons.device_phone_portrait, CupertinoColors.systemTeal),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    _buildTopicRow('Files', CupertinoIcons.doc_fill, CupertinoColors.systemOrange),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context)),
                    ),
                    _buildTopicRow('Trash', CupertinoIcons.delete, CupertinoColors.destructiveRed),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // This code for disconnecting Telegram session
              CupertinoButton(
                onPressed: _disconnectVault,
                child: const Text(
                  'Disconnect Vault',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
              ),
            ],

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Text(
                'Infinity uses a private Telegram supergroup with forum topics as your personal unlimited cloud vault. Photos and videos are stored across organized topics.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // This code for rendering individual forum topic status row
  Widget _buildTopicRow(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Spacer(),
        const Text('Active', style: TextStyle(color: CupertinoColors.activeGreen, fontSize: 13)),
      ],
    );
  }
}
