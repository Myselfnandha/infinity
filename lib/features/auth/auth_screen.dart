import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/di/providers.dart';
import '../../core/telegram/tdlib_service.dart';
import 'telegram_api_extraction_sheet.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendPhoneNumber(phone);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.sendAuthCode(code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.send2FaPassword(password);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestQr() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tdlib = ref.read(tdlibServiceProvider);
      await tdlib.requestQrCode();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider).value ??
        ref.read(tdlibServiceProvider).currentAuthState;

    if (authState == TelegramAuthState.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
    }

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Infinity Login'),
      ),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.infinite,
                  size: 72,
                  color: CupertinoColors.activeBlue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Infinity Cloud Vault',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unlimited Photo & Video Storage on Telegram',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (authState == TelegramAuthState.waitingForCode) ...[
                  CupertinoTextField(
                    controller: _codeController,
                    placeholder: 'Enter Telegram Code',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(14),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(CupertinoIcons.lock_shield),
                    ),
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
                    placeholder: 'Enter 2FA Password',
                    obscureText: true,
                    padding: const EdgeInsets.all(14),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(CupertinoIcons.lock),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _isLoading ? null : _submitPassword,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('Submit Password'),
                  ),
                ] else if (authState == TelegramAuthState.waitingForQrCode) ...[
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          CupertinoIcons.qrcode,
                          size: 160,
                          color: CupertinoColors.label,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Scan with Telegram App',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Settings > Devices > Link Desktop Device',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton(
                    onPressed: () {
                      ref.read(tdlibServiceProvider);
                    },
                    child: const Text('Back to Phone Login'),
                  ),
                ] else ...[
                  CupertinoTextField(
                    controller: _phoneController,
                    placeholder: 'Phone (+1234567890)',
                    keyboardType: TextInputType.phone,
                    padding: const EdgeInsets.all(14),
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Icon(CupertinoIcons.phone),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    onPressed: _isLoading ? null : _submitPhone,
                    child: _isLoading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text('Continue with Phone'),
                  ),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: _isLoading ? null : _requestQr,
                    child: const Text('Scan QR Code instead'),
                  ),
                  const SizedBox(height: 12),
                  // 1-tap automated browser extraction for my.telegram.org credentials
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: CupertinoColors.activeBlue.withValues(alpha: 0.12),
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final result = await TelegramApiExtractionSheet.show(context);
                            if (!context.mounted) return;
                            if (result != null) {
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => CupertinoAlertDialog(
                                  title: const Text('Telegram API Connected'),
                                  content: Text(
                                    'Connected API ID: ${result['apiId']} successfully configured.',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      isDefaultAction: true,
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
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
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
