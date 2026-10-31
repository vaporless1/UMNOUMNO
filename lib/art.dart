import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'scene.dart';
import 'state.dart';
import 'util.dart';
import 'icons.dart';

const List<String> sceneIds = [
  'meadow',
  'space',
  'sea',
  'forest',
  'winter',
  'candy'
];
const List<String> hatIds = ['bow', 'cap', 'glasses', 'party', 'astro', 'crown'];
const List<String> frameIds = ['gold', 'rainbow', 'stars', 'hearts'];

String scenePath(String id) =>
    'assets/art/scene_${sceneIds.contains(id) ? id : 'meadow'}.svg';

String bearPath(String hat, {bool tight = false}) {
  final h = hatIds.contains(hat) ? hat : 'none';
  return 'assets/art/${tight ? 'bearhat' : 'bear'}_$h.svg';
}

/// Фон-сцена детского режима (под содержимым экрана): живая, как на сайте.
class Backdrop extends StatelessWidget {
  final Widget child;
  const Backdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (!app.kidMode) return child;
        final art = app.equippedArt('bg');
        final id = sceneIds.contains(art) ? art : 'meadow';
        return Stack(
          children: [
            Positioned.fill(child: SceneView.page(key: ValueKey(id), id: id)),
            Positioned.fill(child: child),
          ],
        );
      },
    );
  }
}

class Mascot extends StatelessWidget {
  final String hat;
  final double height;
  final bool tight;
  const Mascot({super.key, this.hat = '', this.height = 140, this.tight = false});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(bearPath(hat, tight: tight), height: height);
  }
}

class SceneThumb extends StatelessWidget {
  final String art;
  const SceneThumb({super.key, required this.art});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SvgPicture.asset(scenePath(art),
          fit: BoxFit.cover, alignment: Alignment.bottomCenter),
    );
  }
}

/// Аватар (фото или первая буква) с необязательной декоративной рамкой.
class Avatar extends StatelessWidget {
  final String? url;
  final String name;
  final String? color;
  final double size;
  final String frame;

  const Avatar({
    super.key,
    this.url,
    required this.name,
    this.color,
    this.size = 44,
    this.frame = '',
  });

  Widget _core(double d) {
    final bg = hexColor(color);
    final letter = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    final fallback = Center(
      child: Text(letter,
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: d * 0.44)),
    );
    return Container(
      width: d,
      height: d,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url!.isEmpty)
          ? fallback
          : Image.network(url!,
              fit: BoxFit.cover,
              cacheWidth: (d * 3).round(),
              filterQuality: FilterQuality.low,
              errorBuilder: (_, __, ___) => fallback),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!frameIds.contains(frame)) return _core(size);
    final pad = size * 0.14;
    final total = size + pad * 2;
    Widget ring;
    switch (frame) {
      case 'gold':
        ring = Container(
          width: total,
          height: total,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFDE68A), Color(0xFFF59E0B), Color(0xFFD97706)],
            ),
          ),
        );
        break;
      case 'rainbow':
        ring = Container(
          width: total,
          height: total,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: [
              Color(0xFFFF5A5F),
              Color(0xFFFF9F43),
              Color(0xFFFFD93D),
              Color(0xFF6BCF63),
              Color(0xFF4DABF7),
              Color(0xFF9775FA),
              Color(0xFFFF5A5F),
            ]),
          ),
        );
        break;
      default:
        final icon = frame == 'stars' ? Si.star : Si.heart;
        final c1 = frame == 'stars' ? const Color(0xFFFDE047) : Colors.white;
        final c2 = frame == 'stars' ? Colors.white : const Color(0xFFFFE4EF);
        final r = total / 2 - pad * 0.5;
        ring = SizedBox(
          width: total,
          height: total,
          child: Stack(
            children: [
              for (var i = 0; i < 10; i++)
                Positioned(
                  left: total / 2 + cos(i / 10 * 2 * pi) * r - pad * 0.6,
                  top: total / 2 + sin(i / 10 * 2 * pi) * r - pad * 0.6,
                  child: Ic(icon,
                      fill: true,
                      size: pad * 1.2, color: i.isEven ? c1 : c2),
                ),
            ],
          ),
        );
    }
    return SizedBox(
      width: total,
      height: total,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ring,
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: _core(size - 4 + (pad * 0.6)),
          ),
        ],
      ),
    );
  }
}

class StarsRow extends StatelessWidget {
  final int count;
  final double size;
  const StarsRow({super.key, required this.count, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 3; i++)
          Ic(Si.star,
              size: size,
              fill: i <= count,
              color: i <= count ? const Color(0xFFF5B301) : const Color(0xFFDDDDDD)),
      ],
    );
  }
}
