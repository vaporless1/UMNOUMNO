import 'dart:math';

import 'package:flutter/material.dart';
import 'icons.dart';

// ---------- безопасное приведение типов (данные приходят из JSON) ----------
String asStr(dynamic v) => v == null ? '' : v.toString();

int asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(asStr(v)) ?? 0;
}

bool asBool(dynamic v) => v == true;

int starsOf(dynamic v) {
  final n = asInt(v);
  return n < 1 ? 1 : (n > 3 ? 3 : n);
}

List<dynamic> asList(dynamic v) => v is List ? v : <dynamic>[];

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<Map<String, dynamic>> rows(dynamic v) =>
    asList(v).map((e) => asMap(e)).toList();

// ---------- текст ----------
String plural(int n, String a, String b, String c) {
  final m = n % 10, h = n % 100;
  if (h > 10 && h < 15) return c;
  if (m == 1) return a;
  if (m > 1 && m < 5) return b;
  return c;
}

String ageT(int n) => '$n ${plural(n, 'год', 'года', 'лет')}';

String _two(int n) => n < 10 ? '0$n' : '$n';

String fd(dynamic d) {
  final t = DateTime.tryParse(asStr(d));
  if (t == null) return '—';
  final l = t.toLocal();
  return '${_two(l.day)}.${_two(l.month)}.${l.year}';
}

String fmtT(int s) => '${s ~/ 60}:${_two(s % 60)}';

final RegExp unameRe = RegExp(r'^[a-z0-9_]{3,20}$');

String cleanUname(String v) =>
    v.trim().replaceFirst(RegExp(r'^@'), '').toLowerCase();

const Map<String, String> planNames = {
  'none': 'Нет подписки',
  'trial': 'Пробный период',
  'family': 'Семейный',
  'year': 'Годовой',
};

String errText(Object e) {
  final m = e.toString();
  if (m.contains('Invalid login credentials')) {
    return 'Неверная почта или пароль.';
  }
  if (m.contains('Email not confirmed')) {
    return 'Подтвердите почту: мы отправили вам письмо.';
  }
  if (m.contains('already registered')) {
    return 'Этот e-mail уже зарегистрирован. Попробуйте войти.';
  }
  if (m.contains('rate limit')) {
    return 'Слишком много писем за короткое время. Подождите около часа.';
  }
  if (RegExp(r'duplicate key|занят').hasMatch(m)) {
    return 'Этот юзернейм уже занят.';
  }
  if (m.contains('SocketException') ||
      m.contains('ClientException') ||
      m.contains('Failed host lookup') ||
      m.contains('TimeoutException') ||
      m.contains('HandshakeException')) {
    return 'Не удалось связаться с сервером. Проверьте интернет '
        '(если включён VPN, попробуйте выключить или включить его) и повторите.';
  }
  return 'Что-то пошло не так: $m';
}

String uuid4() {
  final r = Random.secure();
  final b = List<int>.generate(16, (_) => r.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  String h(int i) => b[i].toRadixString(16).padLeft(2, '0');
  return '${h(0)}${h(1)}${h(2)}${h(3)}-${h(4)}${h(5)}-${h(6)}${h(7)}-'
      '${h(8)}${h(9)}-${h(10)}${h(11)}${h(12)}${h(13)}${h(14)}${h(15)}';
}

// ---------- оформление ----------
const Map<String, List<int>> themes = {
  'brown': [0xFFB07F5E, 0xFF8F6246],
  'blue': [0xFF4F8EF7, 0xFF2F6FD6],
  'pink': [0xFFE0709A, 0xFFC2527C],
  'green': [0xFF4CAF7D, 0xFF2E8F5E],
  'purple': [0xFF8A63D2, 0xFF6B45B8],
  'orange': [0xFFE8873A, 0xFFC96A1F],
};

Color themeColor(String? k) => Color((themes[k] ?? themes['brown']!)[0]);

const List<Color> kidColors = [
  Color(0xFF4F8EF7),
  Color(0xFFFF6B9D),
  Color(0xFF2FBF71),
  Color(0xFFFF9F43),
  Color(0xFF9775FA),
  Color(0xFF17B8C9),
];

const List<String> profileColors = [
  '#B07F5E',
  '#4f8ef7',
  '#e0709a',
  '#4caf7d',
  '#e8873a',
  '#8a63d2',
];

Color hexColor(String? h, [Color fallback = const Color(0xFFB07F5E)]) {
  if (h == null || h.isEmpty) return fallback;
  var s = h.replaceFirst('#', '');
  if (s.length == 6) s = 'FF$s';
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(v);
}

SIcon iconFor(String? n) {
  const known = <String, SIcon>{
    'abc': Si.abc,
    'globe': Si.globe,
    'puzzle': Si.puzzle,
    'chat': Si.chat,
    'check': Si.check,
    'user': Si.user,
    'flame': Si.flame,
    'trophy': Si.trophy,
    'book': Si.book,
    'music': Si.music,
    'brush': Si.brush,
    'rocket': Si.rocket,
    'crown': Si.crown,
    'lock': Si.lock,
    'gear': Si.gear,
    'home': Si.home,
    'chart': Si.chart,
    'baby': Si.baby,
    'image': Si.image,
    'edit': Si.edit,
    'video': Si.video,
    'sound': Si.sound,
    'mute': Si.mute,
    'shop': Si.shop,
    'play': Si.play,
    'heart': Si.heart,
    'clock': Si.clock,
    'gift': Si.gift,
    'star': Si.star,
  };
  return known[n] ?? Si.star;
}

// ---------- ссылки на видео ----------
class VideoSrc {
  final String kind; // 'iframe' или 'file'
  final String url;
  const VideoSrc(this.kind, this.url);
}

VideoSrc? videoSrc(String? u) {
  if (u == null || u.trim().isEmpty) return null;
  final s = u.trim();
  var m = RegExp(r'(?:youtu\.be/|youtube\.com/(?:watch\?v=|embed/|shorts/))([\w-]{11})')
      .firstMatch(s);
  if (m != null) {
    return VideoSrc(
        'iframe', 'https://www.youtube-nocookie.com/embed/${m.group(1)}?rel=0');
  }
  m = RegExp(r'rutube\.ru/(?:video|play/embed)/([a-f0-9]{32})').firstMatch(s);
  if (m != null) {
    return VideoSrc('iframe', 'https://rutube.ru/play/embed/${m.group(1)}');
  }
  m = RegExp(r'vimeo\.com/(?:video/)?(\d+)').firstMatch(s);
  if (m != null) {
    return VideoSrc('iframe', 'https://player.vimeo.com/video/${m.group(1)}');
  }
  if (s.startsWith('https://') &&
      RegExp(r'\.(mp4|webm|mov)(\?|$)', caseSensitive: false).hasMatch(s)) {
    return VideoSrc('file', s);
  }
  return null;
}
