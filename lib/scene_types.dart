/// Описание анимированного слоя сцены (рисунок + как он двигается).
class SLayer {
  final String svg; // SVG слоя; его viewBox = [vb]
  final int kind; // см. scene.dart
  final List<double> m; // матрица слоя в координатах сцены (a b c d e f)
  final List<double> vb; // x y w h области SVG
  final List<double> bb; // x y w h самого предмета (для точки вращения)
  final double? dur;
  final double delay;
  final int parent; // -1, либо номер слоя, к которому «прикреплён»
  const SLayer(this.svg, this.kind, this.m, this.vb, this.bb, this.dur,
      this.delay, this.parent);
}

/// Частица: звезда, пузырёк или снежинка.
class SPart {
  final int kind; // 0 мерцает, 1 пузырёк, 2 снежинка
  final double cx, cy, r;
  final int fill, stroke;
  final double sw, op;
  final double? dur;
  final double delay;
  const SPart(this.kind, this.cx, this.cy, this.r, this.fill, this.stroke,
      this.sw, this.op, this.dur, this.delay);
}

class SceneData {
  final int top; // цвет неба сверху (для продления на высоких экранах)
  final String base;
  final List<SLayer> layers;
  final List<SPart> parts;
  const SceneData(this.top, this.base, this.layers, this.parts);
}
