import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'scene_data.dart';
import 'scene_types.dart';

// Анимированные фоны-сцены и маскот: те же рисунки и движения, что на сайте.
// Рисунок разрезан на неподвижную основу и подвижные слои (облака, солнце,
// рыбки…). Слои двигаются на видеокарте, поэтому приложение не тормозит.

// виды слоёв
const int _kCloud = 0, _kSpin = 1, _kFly = 2, _kSway = 3, _kFish = 4;
const int _kJelly = 5, _kRocket = 6, _kFlame = 7, _kUfo = 8;
const int _kWave = 9, _kBlink = 10;

const List<double> _defDur = [70, 40, 4, 4, 16, 5, 3, 0.35, 4, 1.3, 5];

/// Какой кусок сцены показывать на узком экране телефона.
const Map<String, double> _focusX = {
  'meadow': 1050,
  'space': 1050,
  'sea': 900,
  'forest': 800,
  'winter': 520,
  'candy': 900,
};

double _loop(double t, double dur, double delay) {
  final p = ((t - delay) / dur) % 1.0;
  return p < 0 ? p + 1 : p;
}

double _alt(double t, double dur, double delay) {
  var c = ((t - delay) / dur) % 2.0;
  if (c < 0) c += 2;
  final u = c <= 1 ? c : 2 - c;
  return Curves.easeInOut.transform(u);
}

Matrix4 _aff(List<double> m) =>
    Matrix4(m[0], m[1], 0, 0, m[2], m[3], 0, 0, 0, 0, 1, 0, m[4], m[5], 0, 1);

Matrix4 _about(double px, double py, Matrix4 m) {
  return Matrix4.translationValues(px, py, 0)
      .multiplied(m)
      .multiplied(Matrix4.translationValues(-px, -py, 0));
}

Matrix4 _anim(SLayer l, double t) {
  final dur = l.dur ?? _defDur[l.kind];
  final bb = l.bb;
  switch (l.kind) {
    case _kCloud:
      return Matrix4.translationValues(-90 + 220 * _alt(t, dur, l.delay), 0, 0);
    case _kSpin:
      return Matrix4.rotationZ(2 * pi * _loop(t, dur, l.delay));
    case _kFly:
      final u = _alt(t, dur, l.delay);
      return Matrix4.translationValues(-16 + 38 * u, 6 - 30 * u, 0);
    case _kSway:
      final a = (-6 + 12 * _alt(t, dur, l.delay)) * pi / 180;
      return _about(bb[0] + bb[2] / 2, bb[1] + bb[3], Matrix4.rotationZ(a));
    case _kFish:
      return Matrix4.translationValues(-120 + 280 * _alt(t, dur, l.delay), 0, 0);
    case _kJelly:
    case _kUfo:
      return Matrix4.translationValues(0, -10 + 24 * _alt(t, dur, l.delay), 0);
    case _kRocket:
      final u = _alt(t, dur, l.delay);
      return Matrix4.translationValues(-8 + 18 * u, 6 - 16 * u, 0);
    case _kFlame:
      final s = 0.8 + 0.4 * _alt(t, dur, l.delay);
      return _about(bb[0] + bb[2] / 2, bb[1], Matrix4.diagonal3Values(1, s, 1));
    case _kWave:
      final a = (-6 + 22 * _alt(t, dur, l.delay)) * pi / 180;
      return _about(
          bb[0] + bb[2] * 0.3, bb[1] + bb[3] * 0.95, Matrix4.rotationZ(a));
    case _kBlink:
      final p = _loop(t, dur, l.delay);
      double s = 1;
      if (p >= 0.92 && p < 0.95) {
        s = 1 - 0.9 * ((p - 0.92) / 0.03);
      } else if (p >= 0.95) {
        s = 0.1 + 0.9 * ((p - 0.95) / 0.05);
      }
      return _about(bb[0] + bb[2] / 2, bb[1] + bb[3] / 2,
          Matrix4.diagonal3Values(1, s, 1));
  }
  return Matrix4.identity();
}

Matrix4 _full(List<SLayer> ls, int i, double t) {
  final l = ls[i];
  final base = l.parent >= 0 ? _full(ls, l.parent, t) : Matrix4.identity();
  return base.multiplied(_aff(l.m)).multiplied(_anim(l, t));
}

/// Все подвижные слои. Располагаются в координатах сцены.
List<Widget> _layerWidgets(List<SLayer> ls, ValueNotifier<double> t,
    {Offset shift = Offset.zero}) {
  return [
    for (var i = 0; i < ls.length; i++)
      Positioned(
        left: 0,
        top: 0,
        child: AnimatedBuilder(
          animation: t,
          child: RepaintBoundary(
            child: SvgPicture.string(ls[i].svg,
                width: ls[i].vb[2], height: ls[i].vb[3]),
          ),
          builder: (context, child) {
            final m = Matrix4.translationValues(shift.dx, shift.dy, 0)
                .multiplied(_full(ls, i, t.value))
                .multiplied(
                    Matrix4.translationValues(ls[i].vb[0], ls[i].vb[1], 0));
            return Transform(transform: m, child: child);
          },
        ),
      ),
  ];
}

class _PartsPainter extends CustomPainter {
  final List<SPart> parts;
  final ValueNotifier<double> time;
  _PartsPainter(this.parts, this.time) : super(repaint: time);

  final Paint _p = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    for (final s in parts) {
      double dy = 0;
      double o = 1;
      switch (s.kind) {
        case 0: // мерцание
          final p = _loop(t, s.dur ?? 3, s.delay);
          final u = p < 0.5
              ? Curves.easeInOut.transform(p * 2)
              : 1 - Curves.easeInOut.transform((p - 0.5) * 2);
          o = 1 - 0.75 * u;
          break;
        case 1: // пузырёк
          final p = _loop(t, s.dur ?? 8, s.delay);
          dy = -240 * p;
          o = p < 0.15 ? p / 0.15 : 1 - (p - 0.15) / 0.85;
          break;
        default: // снежинка
          dy = 960 * _loop(t, s.dur ?? 12, s.delay);
      }
      final c = Offset(s.cx, s.cy + dy);
      if (s.fill != 0) {
        final col = Color(s.fill);
        _p
          ..style = PaintingStyle.fill
          ..color = col.withOpacity(col.opacity * o * s.op);
        canvas.drawCircle(c, s.r, _p);
      }
      if (s.stroke != 0 && s.sw > 0) {
        final col = Color(s.stroke);
        _p
          ..style = PaintingStyle.stroke
          ..strokeWidth = s.sw
          ..color = col.withOpacity(col.opacity * o * s.op);
        canvas.drawCircle(c, s.r, _p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PartsPainter old) => false;
}

/// Сцена. [SceneView.page] — фон всего экрана, [SceneView.crop] — окошко
/// (например, в приветствии) с необязательными предметами поверх.
class SceneView extends StatefulWidget {
  final String id;
  final Rect? view;
  final List<Widget> overlays;
  const SceneView.page({super.key, required this.id})
      : view = null,
        overlays = const [];
  const SceneView.crop(
      {super.key, required this.id, required Rect this.view, this.overlays = const []});

  @override
  State<SceneView> createState() => _SceneViewState();
}

class _SceneViewState extends State<SceneView>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> time = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => time.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sd = sceneData[widget.id] ?? sceneData['meadow']!;
    final content = SizedBox(
      width: 1600,
      height: 900,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: SvgPicture.string(sd.base, width: 1600, height: 900),
            ),
          ),
          if (sd.parts.isNotEmpty)
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(painter: _PartsPainter(sd.parts, time)),
              ),
            ),
          ..._layerWidgets(sd.layers, time),
          ...widget.overlays,
        ],
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth, h = c.maxHeight;
      double s, left, top;
      final v = widget.view;
      if (v != null) {
        s = max(w / v.width, h / v.height);
        left = (w - v.width * s) / 2 - v.left * s;
        top = (h - v.height * s) / 2 - v.top * s;
      } else if (w / h < 0.9) {
        // телефон: показываем кусок шириной 900, а небо продолжаем вверх
        s = w / 900;
        final fx = _focusX[widget.id] ?? 800;
        final vx = (fx - 450).clamp(0.0, 700.0).toDouble();
        left = -vx * s;
        top = h - 900 * s;
      } else {
        s = max(w / 1600, h / 900);
        left = (w - 1600 * s) / 2;
        top = h - 900 * s;
      }
      return ClipRect(
        child: ColoredBox(
          color: Color(sd.top),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: left,
                top: top,
                width: 1600 * s,
                height: 900 * s,
                child: FittedBox(fit: BoxFit.fill, child: content),
              ),
            ],
          ),
        ),
      );
    });
  }
}

/// Живой мишка: моргает и машет лапой.
class MascotAnim extends StatefulWidget {
  final String hat;
  final double height;
  const MascotAnim({super.key, this.hat = '', this.height = 140});

  @override
  State<MascotAnim> createState() => _MascotAnimState();
}

class _MascotAnimState extends State<MascotAnim>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<double> time = ValueNotifier<double>(0);
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => time.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = mascotBase.containsKey(widget.hat) ? widget.hat : 'none';
    return SizedBox(
      height: widget.height,
      child: AspectRatio(
        aspectRatio: 300 / 420,
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 300,
            height: 420,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: SvgPicture.string(mascotBase[key]!, width: 300, height: 420),
                ),
                // у мишки начало координат на 50 выше левого верхнего угла
                ..._layerWidgets(mascotLayers, time, shift: const Offset(0, 50)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
