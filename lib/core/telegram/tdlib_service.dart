import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:handy_tdlib_next/handy_tdlib_next.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  TelegramAuthState _currentAuthState = TelegramAuthState.uninitialized;
  TelegramAuthState get currentAuthState => _currentAuthState;

  String? _qrCodeLink;
  String? get qrCodeLink => _qrCodeLink;

  String? _authPhoneNumber;
  String? get authPhoneNumber => _authPhoneNumber;

  int? _vaultChatId;
  int? get vaultChatId => _vaultChatId;

  // This code for caching forum topic thread IDs mapped by topic name
  final Map<int, int> _topicMap = {};
  Map<int, int> get topicMap => Map.unmodifiable(_topicMap);

  // This code for mapping topic names (Photos, Videos, Files, etc.) to their Telegram messageThreadIds
  final Map<String, int> _namedTopicMap = {};
  Map<String, int> get namedTopicMap => Map.unmodifiable(_namedTopicMap);

  // This code for resolving Telegram topic ID by media category or album name
  int getTopicIdForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('video')) {
      return _namedTopicMap['Videos'] ?? _topicMap.values.firstOrNull ?? 1;
    } else if (lower.contains('screen')) {
      return _namedTopicMap['Screenshots'] ?? _topicMap.values.firstOrNull ?? 1;
    } else if (lower.contains('file') ||
        lower.contains('doc') ||
        lower.contains('pdf') ||
        lower.contains('zip')) {
      return _namedTopicMap['Files'] ?? _topicMap.values.firstOrNull ?? 1;
    } else if (lower.contains('trash')) {
      return _namedTopicMap['Trash'] ?? _topicMap.values.firstOrNull ?? 1;
    }
    return _namedTopicMap['Photos'] ?? _topicMap.values.firstOrNull ?? 1;
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

  // Awaits completion of TDLib parameter initialization before processing subsequent commands
  Future<void> _ensureParametersSet({int? apiId, String? apiHash}) async {
    if (_parametersSet) return;
    await initialize(apiId: apiId, apiHash: apiHash);
    if (_parametersSet) return;
    try {
      await _parametersCompleter.future.timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  // Stops the background receive isolate cleanly to avoid race conditions or duplicate polling loops
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

  // Restarts the TDLib client session cleanly when switching API credentials
  Future<void> restartClient({int? apiId, String? apiHash}) async {
    if (_clientId != 0) {
      try {
        await sendAsync(const Close());
      } catch (_) {}
    }
    _stopReceiveLoop();
    _isInitialized = false;
    _clientId = 0;
    _parametersSet = false;
    _parametersCompleter = Completer<void>();
    _pendingRequests.clear();
    _currentAuthState = TelegramAuthState.uninitialized;
    _authStateController.add(_currentAuthState);

    await initialize(apiId: apiId, apiHash: apiHash);
  }

  // Resets auth state to phone number entry from QR mode
  void resetToPhoneNumber() {
    _qrCodeLink = null;
    _currentAuthState = TelegramAuthState.waitingForPhoneNumber;
    _authStateController.add(_currentAuthState);
  }

  Future<void> initialize({int? apiId, String? apiHash}) async {
    if (_isInitialized && _clientId != 0) return;

    if (apiId != null) _activeApiId = apiId;
    if (apiHash != null) _activeApiHash = apiHash;

    try {
      if (kIsWeb) {
        return;
      }

      final libName = Platform.isAndroid ? 'libtdjson.so' : null;
      await TdPlugin.initialize(libName);

      // Throttle TDLib log verbosity on initialization to eliminate logcat flooding (100 log entries/sec)
      try {
        TdPlugin.instance.tdExecute(jsonEncode({
          '@type': 'setLogVerbosityLevel',
          'new_verbosity_level': 1,
        }));
      } catch (_) {}

      _clientId = TdPlugin.instance.tdCreateClientId();
      _isInitialized = true;
      _startReceiveLoop(apiId: apiId, apiHash: apiHash);
    } catch (e) {
      _currentAuthState = TelegramAuthState.error;
      _authStateController.add(_currentAuthState);
    }
  }

  // Spawns a dedicated background Dart Isolate for tdReceive(0.02) to unblock the Flutter UI thread
  void _startReceiveLoop({int? apiId, String? apiHash}) async {
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
    } catch (_) {
      // In testing environments or unsupported platforms, gracefully reset flag
      _isReceiving = false;
      return;
    }

    receivePort.listen((message) {
      if (message is SendPort) {
        _isolateCommandPort = message;
      } else if (message is String) {
        try {
          final tdObject = convertJsonToObject(message);
          if (tdObject != null) {
            _handleIncomingObject(tdObject, apiId: apiId, apiHash: apiHash);
          }
        } catch (_) {}
      }
    });
  }

  // Dedicated background Isolate worker for tdReceive loop to avoid blocking Flutter UI thread
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

  void _handleIncomingObject(TdObject object, {int? apiId, String? apiHash}) {
    if (object.extra != null) {
      final extraKey = object.extra.toString();
      final completer = _pendingRequests.remove(extraKey);
      if (completer != null && !completer.isCompleted) {
        completer.complete(object);
      }
    }

    if (object is UpdateAuthorizationState) {
      _handleAuthState(object.authorizationState, apiId: apiId, apiHash: apiHash);
    }

    _updateController.add(object);
  }

  Future<void> _handleAuthState(AuthorizationState state,
      {int? apiId, String? apiHash}) async {
    if (state is AuthorizationStateWaitTdlibParameters) {
      final appDir = await getApplicationDocumentsDirectory();
      final dbDir = '${appDir.path}/tdlib';
      final filesDir = '${appDir.path}/tdlib_files';

      // This code for resolving Telegram API credentials prioritizing runtime arguments, stored preferences, or verified defaults
      final prefs = await SharedPreferences.getInstance();
      final finalApiId = apiId ?? prefs.getInt('telegram_api_id') ?? defaultApiId;
      final finalApiHash = apiHash ?? prefs.getString('telegram_api_hash') ?? defaultApiHash;

      _activeApiId = finalApiId;
      _activeApiHash = finalApiHash;

      final isTelegramAndroid = finalApiId == 6;
      final deviceModel = isTelegramAndroid
          ? (Platform.isAndroid ? 'Android' : 'Desktop')
          : (Platform.isAndroid ? 'Android' : 'Desktop');
      final systemVersion = isTelegramAndroid && Platform.isAndroid
          ? 'SDK 34'
          : (Platform.operatingSystemVersion.isNotEmpty
              ? Platform.operatingSystemVersion
              : 'Android 14');
      final appVersion = isTelegramAndroid ? '10.14.0' : '1.0.0';

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

  // This code for requesting QR code pairing authentication link
  Future<void> requestQrCode() async {
    await _ensureParametersSet();
    final res = await sendAsync(
      const RequestQrCodeAuthentication(otherUserIds: []),
    );
    if (res is TdError) {
      throw Exception(res.message);
    }
  }

  Future<void> logOut() async {
    await sendAsync(const LogOut());
  }

  Future<void> _findOrCreateVault() async {
    try {
      final chatsRes = await sendAsync(
        const GetChats(chatList: ChatListMain(), limit: 100),
      );
      if (chatsRes is Chats) {
        for (final id in chatsRes.chatIds) {
          final chatInfo = await sendAsync(GetChat(chatId: id));
          if (chatInfo is Chat && chatInfo.title == 'Infinity Vault') {
            _vaultChatId = chatInfo.id;
            await _ensureDefaultTopics();
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
        _vaultChatId = created.id;
        await _ensureDefaultTopics();
      }
    } catch (_) {}
  }

  Future<void> _ensureDefaultTopics() async {
    if (_vaultChatId == null) return;

    final defaultTopicNames = ['Photos', 'Videos', 'Screenshots', 'Trash', 'Files'];
    for (final name in defaultTopicNames) {
      await createTopic(name);
    }
  }

  Future<int?> createTopic(String name) async {
    if (_vaultChatId == null) return null;

    final res = await sendAsync(
      CreateForumTopic(
        chatId: _vaultChatId!,
        name: name,
        icon: const ForumTopicIcon(color: 0x6FB9F0, customEmojiId: 0),
      ),
    );

    if (res is ForumTopicInfo) {
      // This code for recording both raw thread ID and named mapping for the created forum topic
      _topicMap[res.messageThreadId] = res.messageThreadId;
      _namedTopicMap[name] = res.messageThreadId;
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
    if (_vaultChatId == null) return null;

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
        chatId: _vaultChatId!,
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
  }
}
