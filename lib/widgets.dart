import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';
import 'state.dart';
import 'util.dart';
import 'voice.dart';
import 'icons.dart';
import 'theme.dart';

Future<void> openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}

Future<void> openDoc(String file) => openUrl('$siteUrl/$file');

void toast(BuildContext context, String msg, {bool err = false}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    content: Text(msg),
    backgroundColor: err ? const Color(0xFFC0392B) : const Color(0xFF111111),
    behavior: SnackBarBehavior.floating,
  ));
}

/// Белая карточка-блок.
class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  const Box({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin = const EdgeInsets.only(top: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class H2 extends StatelessWidget {
  final String text;
  const H2(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: hd(19)),
      );
}

class Muted extends StatelessWidget {
  final String text;
  final double size;
  const Muted(this.text, {super.key, this.size = 13});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: TextStyle(fontSize: size, color: Colors.black54));
}

class MsgText extends StatelessWidget {
  final String text;
  final bool err;
  final bool ok;
  const MsgText(this.text, {super.key, this.err = false, this.ok = false});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: err
                  ? const Color(0xFFC0392B)
                  : ok
                      ? const Color(0xFF2E7D4F)
                      : Colors.black54)),
    );
  }
}

class Chip2 extends StatelessWidget {
  final SIcon icon;
  final String text;
  final Color color;
  const Chip2(this.icon, this.text, {super.key, this.color = const Color(0xFFFFB800)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), offset: Offset(0, 3)),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Ic(icon, size: 20, color: color),
        const SizedBox(width: 5),
        Text(text, style: hd(17)),
      ]),
    );
  }
}

/// Строка с галочкой и текстом (для согласий и настроек).
class CheckRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  const CheckRow(
      {super.key,
      required this.value,
      required this.onChanged,
      required this.text});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
          Expanded(
              child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(text, style: const TextStyle(fontSize: 13.5)),
          )),
        ]),
      ),
    );
  }
}

/// Ссылки на юридические документы сайта.
class DocLinks extends StatelessWidget {
  final bool consent;
  const DocLinks({super.key, this.consent = false});

  @override
  Widget build(BuildContext context) {
    final items = <MapEntry<String, String>>[
      MapEntry('Политика конфиденциальности', 'privacy.html'),
      MapEntry('Пользовательское соглашение', 'terms.html'),
      if (consent) MapEntry('Согласие на обработку ПДн', 'consent.html'),
      MapEntry('Cookie', 'cookies.html'),
    ];
    return Wrap(
      spacing: 4,
      children: [
        for (final e in items)
          TextButton(
            style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            onPressed: () => openDoc(e.value),
            child: Text(e.key, style: const TextStyle(fontSize: 12.5)),
          ),
      ],
    );
  }
}

Future<bool> confirmDialog(BuildContext context, String title, String text,
    {String ok = 'Да'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Верхняя панель: в детском режиме — звёзды, серия, магазин, голос, выход.
void Function(BuildContext context)? shopOpener;

PreferredSizeWidget? buildBar(BuildContext context,
    {String? title, bool home = false}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(kToolbarHeight),
    child: ListenableBuilder(
      listenable: app,
      builder: (context, _) => _bar(context, title, home),
    ),
  );
}

Widget _barBtn(String tip, SIcon icon, VoidCallback? onTap) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x1F000000), offset: Offset(0, 3))],
        ),
        child: IconButton(
          tooltip: tip,
          icon: Ic(icon, size: 21),
          onPressed: onTap,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        ),
      ),
    );

Widget _bar(BuildContext context, String? title, bool home) {
  final kid = app.kidMode;
  final canPop = Navigator.of(context).canPop();
  final primary = Theme.of(context).colorScheme.primary;
  final titleW = title != null
      ? Text(title, style: hd(18))
      : Text.rich(
          TextSpan(
            style: hd(kid ? 28 : 26),
            children: [
              const TextSpan(text: 'УМ'),
              TextSpan(text: 'НО', style: TextStyle(color: primary)),
            ],
          ),
        );
  final actions = <Widget>[];
  if (kid) {
    actions.add(Chip2(Si.star, '${app.balance}'));
    actions.add(const SizedBox(width: 6));
    actions.add(Chip2(Si.flame, '${asInt(app.stats['streak'])}',
        color: const Color(0xFFFF7A1A)));
    actions.add(_barBtn('Магазин', Si.shop,
        () => shopOpener?.call(context)));
    actions.add(_barBtn(
        'Озвучка заданий',
        app.voicePref ? Si.sound : Si.mute,
        () {
          final on = !app.voicePref;
          app.setVoicePref(on);
          if (!on) Voice.stop();
        }));
    actions.add(_barBtn('Выйти из режима ребёнка', Si.lock,
        () => exitKidFlow(context)));
  }
  return AppBar(
    automaticallyImplyLeading: false,
    leading: (canPop && !home)
        ? IconButton(
            icon: const Ic(Si.back),
            onPressed: () => Navigator.of(context).maybePop())
        : null,
    title: titleW,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    actions: [...actions, const SizedBox(width: 6)],
  );
}

// ---------- PIN и режим ребёнка ----------
Future<String?> askPin(BuildContext context, String title, String text,
    {bool obscure = true}) async {
  final ctrl = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(text),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          obscureText: obscure,
          maxLength: 4,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 26, letterSpacing: 8),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Отмена')),
        FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('Готово')),
      ],
    ),
  );
  return r;
}

Future<void> startKidFlow(BuildContext context) async {
  if (app.kid == null) {
    toast(context, 'Сначала добавьте ребёнка', err: true);
    return;
  }
  if (!app.hasPin) {
    final pin = await askPin(context, 'Родительский PIN',
        'Придумайте 4 цифры. Без них ребёнок не сможет выйти из детского режима. Можно пропустить, нажав «Отмена».',
        obscure: false);
    if (pin != null) {
      if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
        if (context.mounted) toast(context, 'Нужно ровно 4 цифры', err: true);
        return;
      }
      try {
        await app.setPin(pin);
      } catch (e) {
        if (context.mounted) toast(context, errText(e), err: true);
        return;
      }
    }
  }
  await app.enterKidMode();
  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
}

Future<void> exitKidFlow(BuildContext context) async {
  if (app.hasPin) {
    final pin = await askPin(context, 'Только для родителей', 'Введите PIN-код.');
    if (pin == null) return;
    if (!app.checkPin(pin)) {
      if (context.mounted) toast(context, 'Неверный PIN', err: true);
      return;
    }
  }
  await Voice.stop();
  await app.leaveKidMode();
  if (context.mounted) Navigator.of(context).popUntil((r) => r.isFirst);
}
