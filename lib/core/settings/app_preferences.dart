import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyWifiOnly = 'sync_wifi_only';
  static const String keyChargeOnly = 'sync_charge_only';
  static const String keyInstantSync = 'sync_instant_on_capture';
  static const String keySyncIntervalHours = 'sync_interval_hours';
  static const String keyCacheLimitMb = 'cache_limit_mb';
  static const String keyBiometricLock = 'security_biometric_lock';
  static const String keyDeveloperMode = 'app_developer_mode';
  static const String keyBackupFolders = 'backup_folder_ids';
  static const String keyE2eeEnabled = 'security_e2ee_enabled';
  static const String keyUploadCompression = 'media_upload_compression';
  static const String keyDownloadCompression = 'media_download_compression';
  static const String keyPlaybackOptimized = 'media_playback_optimized';
  static const String keySyncScheduleFrequency = 'sync_schedule_frequency';
  static const String keyTelegramApiId = 'telegram_api_id';
  static const String keyTelegramApiHash = 'telegram_api_hash';

  final SharedPreferences _prefs;

  AppPreferences(this._prefs);

  static Future<AppPreferences> getInstance() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  bool get isOnboardingCompleted =>
      _prefs.getBool(keyOnboardingCompleted) ?? false;

  Future<bool> setOnboardingCompleted(bool value) =>
      _prefs.setBool(keyOnboardingCompleted, value);

  bool get isWifiOnly => _prefs.getBool(keyWifiOnly) ?? true;

  Future<bool> setWifiOnly(bool value) => _prefs.setBool(keyWifiOnly, value);

  bool get isChargeOnly => _prefs.getBool(keyChargeOnly) ?? false;

  Future<bool> setChargeOnly(bool value) =>
      _prefs.setBool(keyChargeOnly, value);

  bool get isInstantSync => _prefs.getBool(keyInstantSync) ?? true;

  Future<bool> setInstantSync(bool value) =>
      _prefs.setBool(keyInstantSync, value);

  int get syncIntervalHours => _prefs.getInt(keySyncIntervalHours) ?? 6;

  Future<bool> setSyncIntervalHours(int hours) =>
      _prefs.setInt(keySyncIntervalHours, hours);

  int get cacheLimitMb => _prefs.getInt(keyCacheLimitMb) ?? 2048;

  Future<bool> setCacheLimitMb(int mb) => _prefs.setInt(keyCacheLimitMb, mb);

  bool get isBiometricLockEnabled =>
      _prefs.getBool(keyBiometricLock) ?? false;

  Future<bool> setBiometricLockEnabled(bool value) =>
      _prefs.setBool(keyBiometricLock, value);

  bool get isDeveloperMode => _prefs.getBool(keyDeveloperMode) ?? false;

  Future<bool> setDeveloperMode(bool value) =>
      _prefs.setBool(keyDeveloperMode, value);

  bool get isE2eeEnabled => _prefs.getBool(keyE2eeEnabled) ?? false;

  Future<bool> setE2eeEnabled(bool value) =>
      _prefs.setBool(keyE2eeEnabled, value);

  // This code for getting user upload compression preference (default false: uncompressed original quality)
  bool get isUploadCompressionEnabled =>
      _prefs.getBool(keyUploadCompression) ?? false;

  // This code for setting user upload compression preference
  Future<bool> setUploadCompressionEnabled(bool value) =>
      _prefs.setBool(keyUploadCompression, value);

  // This code for getting user download compression preference (default false: original file)
  bool get isDownloadCompressionEnabled =>
      _prefs.getBool(keyDownloadCompression) ?? false;

  // This code for setting user download compression preference
  Future<bool> setDownloadCompressionEnabled(bool value) =>
      _prefs.setBool(keyDownloadCompression, value);

  // This code for getting playback optimization preference (default true: smooth streaming for photos/video playback)
  bool get isPlaybackOptimized =>
      _prefs.getBool(keyPlaybackOptimized) ?? true;

  // This code for setting playback optimization preference
  Future<bool> setPlaybackOptimized(bool value) =>
      _prefs.setBool(keyPlaybackOptimized, value);

  // This code for getting customizable background sync frequency ('hourly', 'daily', 'weekly', 'monthly')
  String get syncScheduleFrequency =>
      _prefs.getString(keySyncScheduleFrequency) ?? 'daily';

  // This code for setting customizable background sync frequency
  Future<bool> setSyncScheduleFrequency(String frequency) =>
      _prefs.setString(keySyncScheduleFrequency, frequency);

  List<String> get backupFolderIds =>
      _prefs.getStringList(keyBackupFolders) ?? ['camera', 'screenshots', 'videos'];

  Future<bool> setBackupFolderIds(List<String> folderIds) =>
      _prefs.setStringList(keyBackupFolders, folderIds);

  // This code for getting user configured Telegram API ID
  int? get telegramApiId => _prefs.getInt(keyTelegramApiId);

  // This code for setting user configured Telegram API ID
  Future<bool> setTelegramApiId(int? id) =>
      id == null ? _prefs.remove(keyTelegramApiId) : _prefs.setInt(keyTelegramApiId, id);

  // This code for getting user configured Telegram API Hash
  String? get telegramApiHash => _prefs.getString(keyTelegramApiHash);

  // This code for setting user configured Telegram API Hash
  Future<bool> setTelegramApiHash(String? hash) =>
      hash == null ? _prefs.remove(keyTelegramApiHash) : _prefs.setString(keyTelegramApiHash, hash);
}
