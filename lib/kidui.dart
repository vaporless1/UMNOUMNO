import 'package:flutter/material.dart';

import 'icons.dart';
import 'theme.dart';

// Кирпичики детского оформления: те же цвета, «толстые» тени и скругления,
// что в детском режиме сайта.
const Color kKidText = Color(0xFF4B5A7A);
const Color kKidGreen = Color(0xFF2FBF71);
const Color kKidGreenD = Color(0xFF1D8F52);
const Color kKidYellow = Color(0xFFFFC83D);
const Color kKidYellowInk = Color(0xFF5B3A00);
const Color kKidLine = Color(0xFFE4EBFB);

/// Цвет, смешанный с чёрным (как color-mix на сайте).
Color kdark(Color c, double f) => Color.lerp(c, Colors.black, f)!;

List<BoxShadow> kidShadow([double dy = 8, double a = 0.08]) => [
      BoxShadow(color: kKidInk.withOpacity(a), offset: Offset(0, dy)),
    ];

/// Белая панель с «толстой» тенью снизу (класс .kp на сайте).
class KidPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final Gradient? gradient;
  final Border? border;
  const KidPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(top: 16, bottom: 8),
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? Colors.white : null,
        gradient: gradient,
        border: border,
        borderRadius: BorderRadius.circular(28),
        boxShadow: kidShadow(),
      ),
      child: child,
    );
  }
}

/// Заголовок раздела: белая «таблетка» с жёлтым кружком (.ksec h2).
class KidSection extends StatelessWidget {
  final SIcon icon;
  final String text;
  const KidSection(this.icon, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 20, 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(99),
            boxShadow: kidShadow(5, 0.1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 38,
              height: 38,
              decoration:
                  const BoxDecoration(color: kKidYellow, shape: BoxShape.circle),
              child: Ic(icon, size: 21, color: kKidYellowInk),
            ),
            const SizedBox(width: 10),
            Text(text, style: hd(22)),
          ]),
        ),
      ),
    );
  }
}

/// Мягкая пульсация (кнопка «играть», следующий урок).
class Pulse extends StatefulWidget {
  final Widget child;
  final double to;
  final Duration duration;
  const Pulse(
      {super.key,
      required this.child,
      this.to = 1.07,
      this.duration = const Duration(milliseconds: 2200)});

  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration)
        ..repeat(reverse: true);
  late final Animation<double> _a = Tween<double>(begin: 1, end: widget.to)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _a, child: widget.child);
}

/// Карточка-кнопка: при нажатии «продавливается», как на сайте.
class PressCard extends StatefulWidget {
  final VoidCallback? onTap;
  final Color color;
  final Color shadow;
  final double shadowDy;
  final BorderRadius radius;
  final Gradient? gradient;
  final Border? border;
  final EdgeInsets padding;
  final Widget child;
  const PressCard({
    super.key,
    required this.onTap,
    required this.child,
    this.color = Colors.white,
    this.shadow = const Color(0x1A1F2A44),
    this.shadowDy = 7,
    this.radius = const BorderRadius.all(Radius.circular(26)),
    this.gradient,
    this.border,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  State<PressCard> createState() => _PressCardState();
}

class _PressCardState extends State<PressCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final dy = widget.shadowDy;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        transform: Matrix4.translationValues(0, _down ? dy - 2 : 0, 0),
        padding: widget.padding,
        decoration: BoxDecoration(
          color: widget.gradient == null ? widget.color : null,
          gradient: widget.gradient,
          border: widget.border,
          borderRadius: widget.radius,
          boxShadow: [
            BoxShadow(color: widget.shadow, offset: Offset(0, _down ? 2 : dy)),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// Серое состояние для закрытых курсов.
Widget kidGrey(Widget child) => Opacity(
      opacity: 0.8,
      child: ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0.33, 0.33, 0.33, 0, 0, //
          0, 0, 0, 1, 0,
        ]),
        child: child,
      ),
    );
