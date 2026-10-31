import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'scene.dart';

/// Заставка при запуске: оживший луг, мишка выпрыгивает и машет лапой,
/// буквы УМНО падают одна за другой. Закрывается, когда приложение загрузилось.
class IntroSplash extends StatefulWidget {
  final bool ready;
  final VoidCallback onDone;
  const IntroSplash({super.key, required this.ready, required this.onDone});

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash> with TickerProviderStateMixin {
  late final AnimationController _in =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
        ..forward();
  late final AnimationController _out =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  bool _leaving = false;

  static const List<Color> _letterColors = [
    Color(0xFF4F8EF7),
    Color(0xFFFF6B9D),
    Color(0xFF2FBF71),
    Color(0xFFFF9F43),
  ];

  @override
  void initState() {
    super.initState();
    _in.addStatusListener((s) {
      if (s == AnimationStatus.completed) _tryLeave();
    });
  }

  @override
  void didUpdateWidget(covariant IntroSplash old) {
    super.didUpdateWidget(old);
    _tryLeave();
  }

  void _tryLeave() {
    if (_leaving || !widget.ready || !_in.isCompleted) return;
    _leaving = true;
    _out.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _in.dispose();
    _out.dispose();
    super.dispose();
  }

  Widget _letter(int i, String ch) {
    final start = 0.22 + i * 0.09;
    final curve = Interval(start, min(1.0, start + 0.3), curve: Curves.elasticOut);
    final fade = Interval(start, start + 0.08);
    return AnimatedBuilder(
      animation: _in,
      builder: (context, _) {
        final v = curve.transform(_in.value);
        final o = fade.transform(_in.value);
        final style = GoogleFonts.unbounded(
            fontSize: 58, fontWeight: FontWeight.w800, height: 1.1);
        return Opacity(
          opacity: o,
          child: Transform.translate(
            offset: Offset(0, -150 * (1 - v)),
            child: Transform.rotate(
              angle: (1 - v) * (i.isEven ? -0.5 : 0.5),
              child: Stack(children: [
                Text(ch,
                    style: style.copyWith(
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 9
                          ..strokeJoin = StrokeJoin.round
                          ..color = Colors.white)),
                Text(ch, style: style.copyWith(color: _letterColors[i])),
              ]),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _out,
      builder: (context, child) => Opacity(opacity: 1 - _out.value, child: child),
      child: Material(
        color: const Color(0xFF6EC6FF),
        child: Stack(
          children: [
            const Positioned.fill(child: SceneView.page(id: 'meadow')),
            SafeArea(
              child: LayoutBuilder(builder: (context, c) {
                final mh = min(c.maxHeight * 0.42, 340.0);
                return Column(
                  children: [
                    SizedBox(height: c.maxHeight * 0.08),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 4; i++) _letter(i, 'УМНО'[i]),
                      ],
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: _in,
                      builder: (context, _) {
                        final o = const Interval(0.62, 0.85).transform(_in.value);
                        return Opacity(
                          opacity: o,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - o)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(99),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Color(0x22000000), offset: Offset(0, 4)),
                                ],
                              ),
                              child: Text('Мультики и задания для малышей',
                                  style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1F2A44))),
                            ),
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _in,
                      child: MascotAnim(height: mh),
                      builder: (context, child) {
                        final v = Interval(0.05, 0.6, curve: Curves.elasticOut)
                            .transform(_in.value);
                        return Transform.translate(
                          offset: Offset(0, 220 * (1 - v)),
                          child: Transform.scale(
                            scale: 0.4 + 0.6 * v,
                            alignment: Alignment.bottomCenter,
                            child: child,
                          ),
                        );
                      },
                    ),
                    SizedBox(height: c.maxHeight * 0.05),
                    _Dots(show: _in),
                    SizedBox(height: c.maxHeight * 0.04),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Три прыгающих точки внизу: «загружаемся».
class _Dots extends StatefulWidget {
  final Animation<double> show;
  const _Dots({required this.show});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, widget.show]),
      builder: (context, _) {
        final o = const Interval(0.7, 0.9).transform(widget.show.value);
        return Opacity(
          opacity: o,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Transform.translate(
                  offset: Offset(0, -8 * max(0.0, sin((_c.value * 2 * pi) - i * 0.9))),
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Color(0x33000000), offset: Offset(0, 2)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
