import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'services/api.dart';
import 'services/notifications.dart';
import 'services/tts.dart';

/// 全局状态：设置、药箱、提醒。数据保存在手机本地
class AppState extends ChangeNotifier {
  AppState._();
  static final instance = AppState._();

  static const _kServer = 'serverUrl';
  static const _kToken = 'appToken';
  static const _kScale = 'textScale';
  static const _kRate = 'speechRate';
  static const _kAutoSpeak = 'autoSpeak';
  static const _kPitch = 'speechPitch';
  static const _kMeds = 'medicines';
  static const _kReminders = 'reminders';

  late SharedPreferences _prefs;

  String serverUrl = 'http://192.168.1.100:3000';
  String appToken = '';

  /// 字体放大倍数，默认偏大，方便老人看
  double textScale = 1.15;

  /// 朗读语速（0.3 慢 ~ 0.6 快）
  double speechRate = 0.45;

  /// 朗读音调（0.8 低沉 / 1.0 标准 / 1.2 清亮）
  double speechPitch = 1.0;

  /// 识别完成后自动朗读
  bool autoSpeak = false;

  List<Medicine> medicines = [];
  List<Reminder> reminders = [];

  ApiClient get api => ApiClient(baseUrl: serverUrl, token: appToken);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    serverUrl = _prefs.getString(_kServer) ?? serverUrl;
    appToken = _prefs.getString(_kToken) ?? '';
    textScale = _prefs.getDouble(_kScale) ?? textScale;
    speechRate = _prefs.getDouble(_kRate) ?? speechRate;
    autoSpeak = _prefs.getBool(_kAutoSpeak) ?? false;
    speechPitch = _prefs.getDouble(_kPitch) ?? speechPitch;
    medicines = _decodeList(_prefs.getString(_kMeds), Medicine.fromJson);
    reminders = _decodeList(_prefs.getString(_kReminders), Reminder.fromJson);
  }

  List<T> _decodeList<T>(String? raw, T Function(Map<String, dynamic>) f) {
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => f(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      debugPrint('读取本地数据失败: $e');
      return [];
    }
  }

  // ---------- 设置 ----------

  Future<void> saveSettings({
    String? serverUrl,
    String? appToken,
    double? textScale,
    double? speechRate,
    double? speechPitch,
    bool? autoSpeak,
  }) async {
    if (serverUrl != null) {
      this.serverUrl = serverUrl.trim();
      await _prefs.setString(_kServer, this.serverUrl);
    }
    if (appToken != null) {
      this.appToken = appToken.trim();
      await _prefs.setString(_kToken, this.appToken);
    }
    if (textScale != null) {
      this.textScale = textScale;
      await _prefs.setDouble(_kScale, textScale);
    }
    if (speechRate != null) {
      this.speechRate = speechRate;
      await _prefs.setDouble(_kRate, speechRate);
      await TtsService.instance.setRate(speechRate);
    }
    if (autoSpeak != null) {
      this.autoSpeak = autoSpeak;
      await _prefs.setBool(_kAutoSpeak, autoSpeak);
    }
    if (speechPitch != null) {
      this.speechPitch = speechPitch;
      await _prefs.setDouble(_kPitch, speechPitch);
      await TtsService.instance.setPitch(speechPitch);
    }
    notifyListeners();
  }

  // ---------- 药箱 ----------

  Medicine? medicineById(String? id) {
    if (id == null) return null;
    for (final m in medicines) {
      if (m.id == id) return m;
    }
    return null;
  }

  bool contains(Medicine m) => medicines.any((e) => e.id == m.id);

  Future<void> saveMedicine(Medicine m) async {
    final i = medicines.indexWhere((e) => e.id == m.id);
    if (i >= 0) {
      medicines[i] = m;
    } else {
      medicines.insert(0, m);
    }
    await _saveMeds();
    // 药名改了，同步到提醒
    for (final r in reminders.where((r) => r.medicineId == m.id)) {
      if (r.medicineName != m.displayName) {
        r.medicineName = m.displayName;
        await NotificationService.instance.schedule(r);
      }
    }
    await _saveReminders();
    notifyListeners();
  }

  Future<void> deleteMedicine(Medicine m) async {
    medicines.removeWhere((e) => e.id == m.id);
    await _saveMeds();
    notifyListeners();
  }

  Future<void> _saveMeds() =>
      _prefs.setString(_kMeds, jsonEncode(medicines.map((e) => e.toJson()).toList()));

  // ---------- 提醒 ----------

  Future<void> saveReminder(Reminder r) async {
    final i = reminders.indexWhere((e) => e.id == r.id);
    if (i >= 0) {
      reminders[i] = r;
    } else {
      reminders.add(r);
    }
    await NotificationService.instance.schedule(r);
    await _saveReminders();
    notifyListeners();
  }

  Future<void> deleteReminder(Reminder r) async {
    reminders.removeWhere((e) => e.id == r.id);
    await NotificationService.instance.cancel(r);
    await _saveReminders();
    notifyListeners();
  }

  /// 启动时重新排一遍通知，防止系统清掉
  Future<void> rescheduleAll() async {
    for (final r in reminders) {
      try {
        await NotificationService.instance.schedule(r);
      } catch (e) {
        debugPrint('重新设置提醒失败: $e');
      }
    }
  }

  Future<void> _saveReminders() =>
      _prefs.setString(_kReminders, jsonEncode(reminders.map((e) => e.toJson()).toList()));
}
