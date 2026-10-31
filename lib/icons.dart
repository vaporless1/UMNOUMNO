// Иконки как на сайте УМНО (те же линейные контуры, толщина 1,8).
// Файл создан скриптом, руками не правьте.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SIcon {
  final String name;
  const SIcon(this.name);
}

/// Короткие имена иконок.
class Si {
  Si._();
  static const out = SIcon('out');
  static const x = SIcon('x');
  static const abc = SIcon('abc');
  static const globe = SIcon('globe');
  static const puzzle = SIcon('puzzle');
  static const chat = SIcon('chat');
  static const star = SIcon('star');
  static const check = SIcon('check');
  static const user = SIcon('user');
  static const plus = SIcon('plus');
  static const trash = SIcon('trash');
  static const up = SIcon('up');
  static const down = SIcon('down');
  static const flame = SIcon('flame');
  static const trophy = SIcon('trophy');
  static const book = SIcon('book');
  static const music = SIcon('music');
  static const brush = SIcon('brush');
  static const rocket = SIcon('rocket');
  static const crown = SIcon('crown');
  static const lock = SIcon('lock');
  static const gear = SIcon('gear');
  static const home = SIcon('home');
  static const chart = SIcon('chart');
  static const baby = SIcon('baby');
  static const image = SIcon('image');
  static const edit = SIcon('edit');
  static const video = SIcon('video');
  static const sound = SIcon('sound');
  static const mute = SIcon('mute');
  static const shop = SIcon('shop');
  static const play = SIcon('play');
  static const heart = SIcon('heart');
  static const clock = SIcon('clock');
  static const back = SIcon('back');
  static const gift = SIcon('gift');
  static const eye = SIcon('eye');
  static const eyeoff = SIcon('eyeoff');
  static const ext = SIcon('ext');
  static const cloudoff = SIcon('cloudoff');
  static const block = SIcon('block');
  static const checkc = SIcon('checkc');
  static const noimg = SIcon('noimg');
}

const Map<String, String> _paths = {
  'out': 'M 9 4 H 5 v 16 h 4 M 16 8 l 4 4 l -4 4 M 20 12 H 9',
  'x': 'M 6 6 l 12 12 M 18 6 L 6 18',
  'abc': 'M 4 20 L 12 4 l 8 16 M 7.5 14 h 9',
  'globe': 'M 12 3 a 9 9 0 1 0 0 18 a 9 9 0 0 0 0 -18 z M 3 12 h 18 M 12 3 c 3 3 3 15 0 18 M 12 3 c -3 3 -3 15 0 18',
  'puzzle': 'M 10 4 a 2 2 0 1 1 4 0 v 2 h 4 v 4 h -2 a 2 2 0 1 0 0 4 h 2 v 4 h -4 v -2 a 2 2 0 1 0 -4 0 v 2 H 6 v -4 h 2 a 2 2 0 1 0 0 -4 H 6 V 6 h 4 z',
  'chat': 'M 4 5 h 16 v 11 H 9 l -5 4 z M 8 9 h 8 M 8 12 h 5',
  'star': 'M 12 3 l 2.7 5.6 l 6.1 0.9 l -4.4 4.3 l 1 6.1 L 12 17 l -5.4 2.9 l 1 -6.1 L 3.2 9.5 l 6.1 -0.9 z',
  'check': 'M 5 12.5 l 4.5 4.5 L 19 7',
  'user': 'M 12 4 a 4 4 0 1 0 0 8 a 4 4 0 0 0 0 -8 z M 4 21 c 0 -4.4 3.6 -7 8 -7 s 8 2.6 8 7',
  'plus': 'M 12 5 v 14 M 5 12 h 14',
  'trash': 'M 4 7 h 16 M 9 7 V 4 h 6 v 3 M 6 7 l 1 13 h 10 l 1 -13',
  'up': 'M 12 19 V 5 M 6 11 l 6 -6 l 6 6',
  'down': 'M 12 5 v 14 M 6 13 l 6 6 l 6 -6',
  'flame': 'M 12 3 c 1 4 5 5 5 10 a 5 5 0 0 1 -10 0 c 0 -2 1 -3 2 -4 c 0 2 1 3 2 3 c 0 -3 -1 -5 1 -9 z',
  'trophy': 'M 8 4 h 8 v 5 a 4 4 0 0 1 -8 0 z M 8 6 H 4 v 2 a 3 3 0 0 0 3 3 M 16 6 h 4 v 2 a 3 3 0 0 1 -3 3 M 12 13 v 4 M 8 20 h 8 M 9 17 h 6',
  'book': 'M 4 5 a 2 2 0 0 1 2 -2 h 13 v 16 H 6 a 2 2 0 0 0 -2 2 z M 4 19 a 2 2 0 0 1 2 -2 h 13',
  'music': 'M 9 18 V 6 l 10 -2 v 12 M 9 18 a 3 3 0 1 1 -6 0 a 3 3 0 0 1 6 0 z M 19 16 a 3 3 0 1 1 -6 0 a 3 3 0 0 1 6 0 z',
  'brush': 'M 18 3 l 3 3 l -9 9 l -3 -3 z M 9 12 c -3 0 -4 2 -4 4 c 0 2 -1 3 -2 4 c 4 1 8 0 8 -4',
  'rocket': 'M 14 5 c 3 -2 6 -2 6 -2 s 0 3 -2 6 l -5 5 l -4 -4 z M 9 15 l -4 1 l 1 4 l 4 -1 M 5 19 c 1 -4 3 -6 5 -7',
  'crown': 'M 3 8 l 4 4 l 5 -7 l 5 7 l 4 -4 l -2 11 H 5 z',
  'lock': 'M 6 11 h 12 v 9 H 6 z M 8 11 V 8 a 4 4 0 0 1 8 0 v 3',
  'gear': 'M 12 8 a 4 4 0 1 0 0 8 a 4 4 0 0 0 0 -8 z M 12 2 v 3 M 12 19 v 3 M 2 12 h 3 M 19 12 h 3 M 5 5 l 2 2 M 17 17 l 2 2 M 19 5 l -2 2 M 7 17 l -2 2',
  'home': 'M 3 11 l 9 -8 l 9 8 M 5 10 v 10 h 14 V 10',
  'chart': 'M 4 20 V 4 M 4 20 h 16 M 8 16 v -5 M 12 16 V 8 M 16 16 v -3',
  'baby': 'M 12 3 a 9 9 0 1 0 0 18 a 9 9 0 0 0 0 -18 z M 9 10 h 0.01 M 15 10 h 0.01 M 9 15 c 1 1 5 1 6 0',
  'image': 'M 3 5 h 18 v 14 H 3 z M 3 16 l 5 -5 l 4 4 l 3 -3 l 6 5 M 16 9 h 0.01',
  'edit': 'M 4 20 h 4 L 19 9 l -4 -4 L 4 16 z M 13 7 l 4 4',
  'video': 'M 3 6 h 13 v 12 H 3 z M 16 10 l 5 -3 v 10 l -5 -3',
  'sound': 'M 4 9 v 6 h 4 l 5 4 V 5 L 8 9 z M 16.5 8.5 a 5 5 0 0 1 0 7 M 19 6 a 8.5 8.5 0 0 1 0 12',
  'mute': 'M 4 9 v 6 h 4 l 5 4 V 5 L 8 9 z M 17 9.5 l 4 5 M 21 9.5 l -4 5',
  'shop': 'M 5 8 h 14 l -1.2 12 H 6.2 z M 9 8 V 7 a 3 3 0 0 1 6 0 v 1',
  'play': 'M 7 4.5 l 12 7.5 l -12 7.5 z',
  'heart': 'M 12 20 s -8 -5 -8 -11 a 4.5 4.5 0 0 1 8 -2.8 A 4.5 4.5 0 0 1 20 9 c 0 6 -8 11 -8 11 z',
  'clock': 'M 12 3 a 9 9 0 1 0 0 18 a 9 9 0 0 0 0 -18 z M 12 7 v 5 l 3 2',
  'back': 'M 15 5 l -7 7 l 7 7',
  'gift': 'M 4 11 h 16 v 9 H 4 z M 3 8 h 18 v 3 H 3 z M 12 8 v 12 M 12 8 C 9 8 8 4 10.5 4 S 13 8 12 8 z M 12 8 c 3 0 4 -4 1.5 -4 S 11 8 12 8 z',
  'eye': 'M 2 12 s 4 -7 10 -7 s 10 7 10 7 s -4 7 -10 7 S 2 12 2 12 z M 12 9 a 3 3 0 1 0 0 6 a 3 3 0 0 0 0 -6 z',
  'eyeoff': 'M 2 12 s 4 -7 10 -7 s 10 7 10 7 s -4 7 -10 7 S 2 12 2 12 z M 12 9 a 3 3 0 1 0 0 6 a 3 3 0 0 0 0 -6 z M 4 4 l 16 16',
  'ext': 'M 14 4 h 6 v 6 M 20 4 l -9 9 M 18 13 v 6 H 5 V 6 h 6',
  'cloudoff': 'M 7 18 h 10 a 4 4 0 0 0 0.7 -7.9 A 6 6 0 0 0 6.5 9.5 A 4.5 4.5 0 0 0 7 18 z M 4 4 l 16 16',
  'block': 'M 12 3 a 9 9 0 1 0 0 18 a 9 9 0 0 0 0 -18 z M 5.6 5.6 l 12.8 12.8',
  'checkc': 'M 12 3 a 9 9 0 1 0 0 18 a 9 9 0 0 0 0 -18 z M 8 12.5 l 3 3 l 5 -6',
  'noimg': 'M 3 5 h 18 v 14 H 3 z M 3 16 l 5 -5 l 4 4 l 3 -3 l 6 5 M 4 4 l 16 16',
};

final Map<String, String> _svgCache = {};

String _hex(Color c) {
  final v = c.value & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0')}';
}

String _svg(String name, Color c, double stroke, bool fill) {
  final key = '$name|${c.value}|$stroke|$fill';
  return _svgCache.putIfAbsent(key, () {
    final d = _paths[name] ?? _paths['star']!;
    final col = _hex(c);
    final op = c.opacity < 1 ? ' stroke-opacity="${c.opacity.toStringAsFixed(2)}"' : '';
    final fo = c.opacity < 1 ? ' fill-opacity="${c.opacity.toStringAsFixed(2)}"' : '';
    final f = fill ? 'fill="$col"$fo' : 'fill="none"';
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" $f '
        'stroke="$col"$op stroke-width="$stroke" stroke-linecap="round" '
        'stroke-linejoin="round"><path d="$d"/></svg>';
  });
}

/// Иконка в стиле сайта. Цвет и размер берутся из окружения (как у Icon).
class Ic extends StatelessWidget {
  final SIcon icon;
  final double? size;
  final Color? color;
  final double stroke;
  final bool fill;
  const Ic(this.icon,
      {super.key, this.size, this.color, this.stroke = 1.8, this.fill = false});

  @override
  Widget build(BuildContext context) {
    final t = IconTheme.of(context);
    final s = size ?? t.size ?? 24.0;
    final c = color ?? t.color ?? const Color(0xFF111111);
    return SizedBox(
      width: s,
      height: s,
      child: SvgPicture.string(_svg(icon.name, c, stroke, fill),
          width: s, height: s),
    );
  }
}
