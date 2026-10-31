import 'package:flutter_tts/flutter_tts.dart';

/// Озвучка заданий (синтез речи Android, русский язык).
class Voice {
  static final FlutterTts _t = FlutterTts();
  static bool _inited = false;

  static Future<void> _init() async {
    if (_inited) return;
    _inited = true;
    try {
      await _t.setLanguage('ru-RU');
      await _t.setSpeechRate(0.42);
      await _t.setPitch(1.1);
    } catch (_) {}
  }

  static Future<void> speak(List<String> parts) async {
    final text = parts.where((p) => p.trim().isNotEmpty).join('. ');
    if (text.isEmpty) return;
    try {
      await _init();
      await _t.stop();
      await _t.speak(text);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _t.stop();
    } catch (_) {}
  }
}
