import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:handy_tdlib_next/handy_tdlib_next.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../settings/app_preferences.dart';

enum TelegramAuthState {
  uninitialized,
  waitingForPhoneNumber,
  waitingForCode,
  waitingForPassword,
  waitingForQrCode,
  ready,
  loggingOut,
  closed,
  error,
}

class TdlibService {
  static final TdlibService _instance = TdlibService._internal();
  factory TdlibService() => _instance;
  TdlibService._internal();

  // This code for official Telegram production public API credentials (supports QR code auth)
  static const int officialApiId = 2496;
  static const String officialApiHash = '8da85b0d5b1652522bc46057082da478';

  // This code for centralized fallback Telegram API credentials (workspace verified)
  static const int defaultApiId = 30662321;
  static const String defaultApiHash = 'cf007e0155c41fd1aa9b114b592377e0';

  int _clientId = 0;
  int get clientId => _clientId;

  bool _isInitialized = false;
  bool _isReceiving = false;
  Isolate? _receiveIsolate;
  ReceivePort? _receivePort;
  SendPort? _isolateCommandPort;

  final _updateController = StreamController<TdObject>.broadcast();
  Stream<TdObject> get updates => _updateController.stream;

  final _authStateController = StreamController<TelegramAuthState>.broadcast();
  Stream<TelegramAuthState> get authStateStream => _authStateController.stream;

  // Stream of TDLib UpdateFile events for live upload throughput calculation
  final _fileUpdateController = StreamController<UpdateFile>.broadcast();
  Stream<UpdateFile> get fileUpdateStream => _fileUpdateController.stream;

  TelegramAuthState _currentAuthState = TelegramAuthState.uninitialized;
  TelegramAuthState get currentAuthState => _currentAuthState;

  String? _qrCodeLink;
  String? get qrCodeLink => _qrCodeLink;

  String? _authPhoneNumber;
  String? get authPhoneNumber => _authPhoneNumber;

  int? vaultChatId;

  // This code for caching forum topic thread IDs mapped by topic name
  final Map<int, int> _topicMap = {};
  Map<int, int> get topicMap => Map.unmodifiable(_topicMap);

  // This code for mapping topic names (Photos, Videos, Files, etc.) to their Telegram messageThreadIds
  final Map<String, int> _namedTopicMap = {};
  Map<String, int> get namedTopicMap => Map.unmodifiable(_namedTopicMap);

  // This code for resolving Telegram topic ID by media category or album name
  /// Resolves the forum topic thread ID for a given media category or file type.
  int getTopicIdForCategory(String category) {
    final lower = category.toLowerCase();
    final targetName = switch (lower) {
      _ when lower.contains('video') => 'Videos',
      _ when lower.contains('screen') => 'Screenshots',
      _ when lower.contains('file') ||
          lower.contains('doc') ||
          lower.contains('pdf') ||
          lower.contains('zip') =>
        'Files',
      _ when lower.contains('trash') => 'Trash',
      _ => 'Photos',
    };
    return _namedTopicMap[targetName] ?? _topicMap.values.firstOrNull ?? 1;
  }

  final Map<String, Completer<TdObject>> _pendingRequests = {};
  final Random _random = Random();

  // Active Telegram API credentials applied to the current TDLib session
  int? _activeApiId;
  int? get activeApiId => _activeApiId;

  String? _activeApiHash;
  String? get activeApiHash => _activeApiHash;

  // Synchronization completer to ensure TDLib parameters handshake completes before dispatching auth requests
  Completer<void> _parametersCompleter = Completer<void>();
  bool _parametersSet = false;

  // This code for awaiting completion of TDLib parameter handshake before dispatching requests
  Future<void> _ensureParametersSet({int? apiId, String? apiHash}) async {
    if (_parametersSet) return;
    await initialize(apiId: apiId, apiHash: apiHash);
    if (_parametersSet) return;
    try {
      await _parametersCompleter.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('[TDLib] _ensureParametersSet timeout or wait error: $e');
    }
  }

  // This code for cleanly stopping background receive isolate during full app termination
  void _stopReceiveLoop() {
    _isReceiving = false;
    if (_isolateCommandPort != null) {
      try {
        _isolateCommandPort?.send('stop');
      } catch (_) {}
      _isolateCommandPort = null;
    }
    if (_receivePort != null) {
      try {
        _receivePort?.close();
      } catch (_) {}
      _receivePort = null;
    }
    if (_receiveIsolate != null) {
      try {
        _receiveIsolate?.kill(priority: Isolate.immediate);
      } catch (_) {}
      _receiveIsolate = null;
    }
  }

  // This code for restarting TDLib client session cleanly when switching API credentials
  Future<void> restartClient({int? apiId, String? apiHash}) async {
    debugPrint('[TDLib] Restarting client session with apiId: $apiId...');
    if (_clientId != 0) {
      try {
        await sendAsync(const Close()).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }

    _isInitialized = false;
    _clientId = 0;
    _parametersSet = false;
    _parametersCompleter = Completer<void>();
    _pendingRequests.clear();
    _currentAuthState = TelegramAuthState.uninitialized;
    _authStateController.add(_currentAuthState);

    // Keep the single receive worker loop alive to prevent multiple-thread collision inside tdReceive
    await initialize(apiId: apiId, apiHash: apiHash);
  }

  // This code for resetting auth state to phone number entry from QR mode
  void resetToPhoneNumber() {
    _qrCodeLink = null;
    _currentAuthState = TelegramAuthState.waitingForPhoneNumber;
    _authStateController.add(_currentAuthState);
  }

  // This code for initializing TDLib native dynamic library and client session
  Future<void> initialize({int? apiId, String? apiHash}) async {
    if (_isInitialized && _clientId != 0) return;

    final prefs = await SharedPreferences.getInstance();
    final appPrefs = AppPreferences(prefs);
    if (vaultChatId == null && appPrefs.vaultChatId != null) {
      vaultChatId = appPrefs.vaultChatId;
      final savedTopics = appPrefs.vaultTopics;
      for (final entry in savedTopics.entries) {
        _namedTopicMap[entry.key] = entry.value;
        _topicMap[entry.value] = entry.value;
      }
      debugPrint('[TDLib] Eagerly restored persisted vault chat ID: $vaultChatId with ${savedTopics.length} topics');
    }

    final finalApiId = apiId ?? _activeApiId ?? prefs.getInt('telegram_api_id') ?? defaultApiId;
    final finalApiHash = apiHash ?? _activeApiHash ?? prefs.getString('telegram_api_hash') ?? defaultApiHash;

    _activeApiId = finalApiId;
    _activeApiHash = finalApiHash;

    try {
      if (kIsWeb) {
        return;
      }

      final libName = Platform.isAndroid ? 'libtdjson.so' : null;
      await TdPlugin.initialize(libName);

      // This code for setting TDLib log verbosity to 1 to prevent logcat flooding
      try {
        TdPlugin.instance.tdExecute(jsonEncode({
          '@type': 'setLogVerbosityLevel',
          'new_verbosity_level': 1,
        }));
      } catch (_) {}

      // This code for ensuring TDLib database and file directories exist on disk
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(p.join(appDir.path, 'tdlib'));
      final filesDir = Directory(p.join(appDir.path, 'tdlib_files'));
      if (!dbDir.existsSync()) dbDir.createSync(recursive: true);
      if (!filesDir.existsSync()) filesDir.createSync(recursive: true);

      _clientId = TdPlugin.instance.tdCreateClientId();
      _isInitialized = true;
      debugPrint('[TDLib] TDLib client created with ID: $_clientId (activeApiId: $_activeApiId)');

      _startReceiveLoop();

      // This code for immediately requesting authorization state from TDLib
      try {
        await sendAsync(const GetAuthorizationState()).timeout(const Duration(seconds: 4));
      } catch (_) {}
    } catch (e) {
      debugPrint('[TDLib] Client initialization error: $e');
      _currentAuthState = TelegramAuthState.error;
      _authStateController.add(_currentAuthState);
    }
  }

  // This code for spawning a dedicated background Dart Isolate for tdReceive(0.02) to unblock Flutter UI thread
  void _startReceiveLoop() async {
    if (_isReceiving) return;
    _isReceiving = true;

    final receivePort = ReceivePort();
    _receivePort = receivePort;

    final libName = Platform.isAndroid ? 'libtdjson.so' : null;

    try {
      _receiveIsolate = await Isolate.spawn(
        _tdReceiveIsolateWorker,
        [receivePort.sendPort, libName],
      );
    } catch (e) {
      debugPrint('[TDLib] Failed to spawn receive isolate (fallback mode): $e');
      _isReceiving = false;
      return;
    }

    receivePort.listen((message) {
      if (message is SendPort) {
        _isolateCommandPort = message;
      } else if (message is String) {
        try {
          final decoded = jsonDecode(message);
          if (decoded is Map<String, dynamic>) {
            // Dual-layer defense: sanitize missing boolean keys for AuthorizationStateWaitPassword
            if (decoded['@type'] == 'updateAuthorizationState') {
              final authState = decoded['authorization_state'];
              if (authState is Map<String, dynamic>) {
                if (authState['@type'] == 'authorizationStateWaitPassword') {
                  authState['has_recovery_email_address'] ??= false;
                  authState['has_passport_data'] ??= false;
                }
              }
            }

            TdObject? tdObject;
            try {
              tdObject = convertMapToObject(decoded);
            } catch (convErr) {
              debugPrint('[TDLib] convertMapToObject fallback error: $convErr');
              // Raw map fallback for pending requests resolution via @extra
              final extra = decoded['@extra'];
              if (extra != null) {
                final extraKey = extra.toString();
                final completer = _pendingRequests.remove(extraKey);
                if (completer != null && !completer.isCompleted) {
                  if (decoded['@type'] == 'error') {
                    completer.complete(TdError(
                      code: decoded['code'] as int? ?? 500,
                      message: decoded['message'] as String? ?? 'TDLib Request Error',
                    ));
                  } else {
                    completer.complete(TdError(code: 500, message: 'Deserialization error: $convErr'));
                  }
                }
              }
              // Raw map fallback for auth state detection
              if (decoded['@type'] == 'updateAuthorizationState') {
                final authState = decoded['authorization_state'];
                if (authState is Map<String, dynamic> &&
                    authState['@type'] == 'authorizationStateWaitPassword') {
                  _currentAuthState = TelegramAuthState.waitingForPassword;
                  _authStateController.add(_currentAuthState);
                }
              }
            }

            if (tdObject != null) {
              _handleIncomingObject(tdObject);
            }
          }
        } catch (e) {
          debugPrint('[TDLib] Error parsing incoming TDLib message: $e');
        }
      }
    });
  }

  // This code for dedicated background Isolate worker executing tdReceive in fixed thread
  static void _tdReceiveIsolateWorker(List<dynamic> args) async {
    final SendPort sendPort = args[0] as SendPort;
    final String? libPath = args[1] as String?;

    try {
      await TdPlugin.initialize(libPath);
    } catch (_) {}

    final commandPort = ReceivePort();
    sendPort.send(commandPort.sendPort);

    bool running = true;
    commandPort.listen((msg) {
      if (msg == 'stop') {
        running = false;
        commandPort.close();
      }
    });

    while (running) {
      try {
        final resString = TdPlugin.instance.tdReceive(0.02);
        if (resString != null && resString.isNotEmpty) {
          sendPort.send(resString);
        }
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
  }

  // This code for handling incoming TDLib objects, routing pending request completers, and triggering state machines
  void _handleIncomingObject(TdObject object) {
    if (object.extra != null) {
      final extraKey = object.extra.toString();
      final completer = _pendingRequests.remove(extraKey);
      if (completer != null && !completer.isCompleted) {
        completer.complete(object);
      }
    }

    if (object is UpdateAuthorizationState) {
      _handleAuthState(object.authorizationState);
    }

    // Broadcast file transfer progress updates for real-time telemetry
    if (object is UpdateFile) {
      _fileUpdateController.add(object);
    }

    _updateController.add(object);
  }

  // This code for processing Telegram authorization state transitions
  Future<void> _handleAuthState(AuthorizationState state) async {
    debugPrint('[TDLib] Auth state transition received: ${state.runtimeType}');
    if (state is AuthorizationStateWaitTdlibParameters) {
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = p.join(appDir.path, 'tdlib');
      final filesDir = p.join(appDir.path, 'tdlib_files');

      final prefs = await SharedPreferences.getInstance();
      final finalApiId = _activeApiId ?? prefs.getInt('telegram_api_id') ?? defaultApiId;
      final finalApiHash = _activeApiHash ?? prefs.getString('telegram_api_hash') ?? defaultApiHash;

      _activeApiId = finalApiId;
      _activeApiHash = finalApiHash;

      final isTelegramAndroid = finalApiId == 6 || finalApiId == officialApiId;
      final deviceModel = isTelegramAndroid
          ? 'Android Mobile'
          : (Platform.isAndroid ? 'Android' : 'Desktop');
      final systemVersion = isTelegramAndroid
          ? 'Android 14'
          : (Platform.operatingSystemVersion.isNotEmpty
              ? Platform.operatingSystemVersion
              : 'Android 14');
      final appVersion = isTelegramAndroid ? '10.14.0' : '1.0.0';

      debugPrint('[TDLib] Sending SetTdlibParameters (apiId: $finalApiId)...');
      final res = await sendAsync(
        SetTdlibParameters(
          useTestDc: false,
          databaseDirectory: dbDir,
          filesDirectory: filesDir,
          databaseEncryptionKey: '',
          useFileDatabase: true,
          useChatInfoDatabase: true,
          useMessageDatabase: true,
          useSecretChats: false,
          apiId: finalApiId,
          apiHash: finalApiHash,
          systemLanguageCode: 'en',
          deviceModel: deviceModel,
          systemVersion: systemVersion,
          applicationVersion: appVersion,
        ),
      );

      if (res is! TdError) {
        _parametersSet = true;
        if (!_parametersCompleter.isCompleted) {
          _parametersCompleter.complete();
        }
        debugPrint('[TDLib] SetTdlibParameters confirmed successfully.');
      } else {
        debugPrint('[TDLib] SetTdlibParameters rejected: ${res.message} (code: ${res.code})');
      }
    } else if (state is AuthorizationStateWaitPhoneNumber) {
      _parametersSet = true;
      if (!_parametersCompleter.isCompleted) {
        _parametersCompleter.complete();
      }
      _currentAuthState = TelegramAuthState.waitingForPhoneNumber;
      _authStateController.add(_currentAuthState);
    } else if (state is AuthorizationStateWaitCode) {
      _currentAuthState = TelegramAuthState.waitingForCode;
      _authStateController.add(_currentAuthState);
    } else if (state is AuthorizationStateWaitPassword) {
      _currentAuthState = TelegramAuthState.waitingForPassword;
      _authStateController.add(_currentAuthState);
    } else if (state is AuthorizationStateWaitOtherDeviceConfirmation) {
      _qrCodeLink = state.link;
      _currentAuthState = TelegramAuthState.waitingForQrCode;
      _authStateController.add(_currentAuthState);
    } else if (state is AuthorizationStateReady) {
      _currentAuthState = TelegramAuthState.ready;
      _authStateController.add(_currentAuthState);
      _findOrCreateVault();
    } else if (state is AuthorizationStateLoggingOut) {
      _currentAuthState = TelegramAuthState.loggingOut;
      _authStateController.add(_currentAuthState);
    } else if (state is AuthorizationStateClosed) {
      _currentAuthState = TelegramAuthState.closed;
      _authStateController.add(_currentAuthState);
    }
  }

  Future<TdObject> sendAsync(TdFunction function) {
    final completer = Completer<TdObject>();
    final extra = _random.nextInt(1000000000);
    final extraKey = extra.toString();
    _pendingRequests[extraKey] = completer;

    final jsonMap = function.toJson();
    jsonMap['@extra'] = extra;
    final jsonString = jsonEncode(jsonMap);

    TdPlugin.instance.tdSend(_clientId, jsonString);

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        _pendingRequests.remove(extraKey);
        throw TimeoutException('TDLib request timed out: ${function.runtimeType}');
      },
    );
  }

  // This code for sending international phone number for Telegram authentication
  Future<void> sendPhoneNumber(String phoneNumber) async {
    await _ensureParametersSet();
    _authPhoneNumber = phoneNumber;
    final res = await sendAsync(
      SetAuthenticationPhoneNumber(
        phoneNumber: phoneNumber,
        settings: const PhoneNumberAuthenticationSettings(
          allowFlashCall: false,
          allowMissedCall: false,
          isCurrentPhoneNumber: false,
          hasUnknownPhoneNumber: false,
          allowSmsRetrieverApi: false,
          authenticationTokens: [],
        ),
      ),
    );
    if (res is TdError) {
      throw Exception(res.message);
    }
  }

  // This code for submitting verification code to TDLib
  Future<void> sendAuthCode(String code) async {
    await _ensureParametersSet();
    final res = await sendAsync(CheckAuthenticationCode(code: code));
    if (res is TdError) {
      throw Exception(res.message);
    }
  }

  // This code for submitting 2FA password to TDLib
  Future<void> send2FaPassword(String password) async {
    await _ensureParametersSet();
    final res = await sendAsync(CheckAuthenticationPassword(password: password));
    if (res is TdError) {
      throw Exception(res.message);
    }
  }

  // This code for requesting QR code pairing authentication link with official API fallback
  Future<void> requestQrCode({bool useOfficialApiFallback = true}) async {
    // If the active API ID is not an official client, Telegram servers reject QR code authentication.
    // Seamlessly switch to official API (2496) to generate pairing token.
    if (useOfficialApiFallback && _activeApiId != officialApiId && _activeApiId != 6) {
      debugPrint('[TDLib] Switching to official Telegram API ($officialApiId) for QR code pairing token...');
      await restartClient(apiId: officialApiId, apiHash: officialApiHash);
    }
    await _ensureParametersSet();
    final res = await sendAsync(
      const RequestQrCodeAuthentication(otherUserIds: []),
    );
    if (res is TdError) {
      debugPrint('[TDLib] RequestQrCodeAuthentication error: ${res.message} (code: ${res.code})');
      throw Exception(res.message);
    }
  }

  Future<void> logOut() async {
    await sendAsync(const LogOut());
  }

  Future<void> _findOrCreateVault() async {
    try {
      final appPrefs = AppPreferences(await SharedPreferences.getInstance());
      final chatsRes = await sendAsync(
        const GetChats(chatList: ChatListMain(), limit: 100),
      );
      if (chatsRes is Chats) {
        for (final id in chatsRes.chatIds) {
          final chatInfo = await sendAsync(GetChat(chatId: id));
          if (chatInfo is Chat && chatInfo.title == 'Infinity Vault') {
            vaultChatId = chatInfo.id;
            await _ensureDefaultTopics();
            await appPrefs.setVaultChatId(vaultChatId);
            await appPrefs.setVaultChatTitle('Infinity Vault');
            await appPrefs.setVaultTopics(_namedTopicMap);
            return;
          }
        }
      }

      final created = await sendAsync(
        const CreateNewSupergroupChat(
          title: 'Infinity Vault',
          isForum: true,
          isChannel: false,
          description: 'Personal media vault powered by Infinity',
          messageAutoDeleteTime: 0,
          forImport: false,
        ),
      );

      if (created is Chat) {
        vaultChatId = created.id;
        await _ensureDefaultTopics();
        await appPrefs.setVaultChatId(vaultChatId);
        await appPrefs.setVaultChatTitle('Infinity Vault');
        await appPrefs.setVaultTopics(_namedTopicMap);
      }
    } catch (_) {}
  }

  Future<void> _ensureDefaultTopics() async {
    if (vaultChatId == null) return;

    final defaultTopicNames = ['Photos', 'Videos', 'Screenshots', 'Trash', 'Files'];
    for (final name in defaultTopicNames) {
      if (_namedTopicMap.containsKey(name)) continue;
      await createTopic(name);
    }
  }

  Future<int?> createTopic(String name) async {
    if (vaultChatId == null) return null;

    final res = await sendAsync(
      CreateForumTopic(
        chatId: vaultChatId!,
        name: name,
        icon: const ForumTopicIcon(color: 0x6FB9F0, customEmojiId: 0),
      ),
    );

    if (res is ForumTopicInfo) {
      // This code for recording both raw thread ID and named mapping for the created forum topic
      _topicMap[res.messageThreadId] = res.messageThreadId;
      _namedTopicMap[name] = res.messageThreadId;
      try {
        final appPrefs = AppPreferences(await SharedPreferences.getInstance());
        await appPrefs.setVaultTopics(_namedTopicMap);
      } catch (_) {}
      return res.messageThreadId;
    }
    return null;
  }

  Future<Message?> uploadMedia({
    required String filePath,
    required String mediaType,
    required int topicId,
    String? caption,
  }) async {
    if (vaultChatId == null) return null;

    final formattedCaption = caption != null
        ? FormattedText(text: caption, entities: [])
        : FormattedText(text: '', entities: []);

    InputMessageContent content;
    if (mediaType == 'image') {
      content = InputMessagePhoto(
        photo: InputFileLocal(path: filePath),
        caption: formattedCaption,
        addedStickerFileIds: [],
        width: 0,
        height: 0,
        thumbnail: null,
        selfDestructType: null,
        hasSpoiler: false,
        showCaptionAboveMedia: false,
      );
    } else if (mediaType == 'video') {
      content = InputMessageVideo(
        video: InputFileLocal(path: filePath),
        caption: formattedCaption,
        addedStickerFileIds: [],
        duration: 0,
        width: 0,
        height: 0,
        supportsStreaming: true,
        thumbnail: null,
        selfDestructType: null,
        hasSpoiler: false,
        showCaptionAboveMedia: false,
      );
    } else {
      content = InputMessageDocument(
        document: InputFileLocal(path: filePath),
        caption: formattedCaption,
        thumbnail: null,
        disableContentTypeDetection: false,
      );
    }

    final res = await sendAsync(
      SendMessage(
        chatId: vaultChatId!,
        messageThreadId: topicId,
        inputMessageContent: content,
      ),
    );

    if (res is Message) {
      return res;
    }
    return null;
  }

  Future<void> downloadFile(int fileId, {int priority = 1}) async {
    await sendAsync(
      DownloadFile(
        fileId: fileId,
        priority: priority,
        offset: 0,
        limit: 0,
        synchronous: false,
      ),
    );
  }

  void dispose() {
    _stopReceiveLoop();
    _updateController.close();
    _authStateController.close();
    _fileUpdateController.close();
  }
}
