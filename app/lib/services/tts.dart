import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// 语音朗读（使用手机自带的中文语音引擎）
class TtsService {
  TtsService._();
  static final instance = TtsService._();

  final FlutterTts _tts = FlutterTts();

  /// 正在朗读的文本；为 null 表示没有在读。界面用它切换「朗读 / 停止」按钮
  final ValueNotifier<String?> speaking = ValueNotifier(null);

  bool _ready = false;

  Future<void> init({double rate = 0.45, double pitch = 1.0}) async {
    try {
      await _tts.setLanguage('zh-CN');
      await _tts.setSpeechRate(rate);
      await _tts.setPitch(pitch);
      await _tts.setVolume(1.0);
      _tts.setCompletionHandler(() => speaking.value = null);
      _tts.setCancelHandler(() => speaking.value = null);
      _tts.setErrorHandler((_) => speaking.value = null);
      _ready = true;
    } catch (e) {
      debugPrint('TTS 初始化失败: $e');
    }
  }

  Future<void> setRate(double rate) async {
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  Future<void> setPitch(double pitch) async {
    try {
      await _tts.setPitch(pitch);
    } catch (_) {}
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    if (!_ready) await init();
    await stop();
    speaking.value = text;
    try {
      await _tts.speak(text);
    } catch (e) {
      speaking.value = null;
      debugPrint('朗读失败: $e');
    }
  }

  /// 正在读同一段时停止，否则开始读
  Future<void> toggle(String text) async {
    if (speaking.value == text) {
      await stop();
    } else {
      await speak(text);
    }
  }

  Future<void> stop() async {
    speaking.value = null;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
