import 'dart:math';

import 'package:flutter/material.dart';

import '../art.dart';
import '../kidui.dart';
import '../scene.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import 'home.dart';
import '../icons.dart';
import '../theme.dart';

// =====================================================================
//  Главный экран ребёнка
// =====================================================================
class KidHome extends StatelessWidget {
  const KidHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBar(context, home: true),
      body: Backdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final k = app.kid;
              if (k == null) {
                return const Center(child: Text('Профиль ребёнка не найден'));
              }
              return _content(context, k);
            },
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Map<String, dynamic> k) {
    final lim = asInt(k['daily_limit']);
    final left = lim > 0 ? max(0, lim - asInt(app.stats['today'])) : 0;
    final stop = app.limitReached;
    final cont = app.continueTarget();
    final rec = app.recentLessons(6);
    final hello = stop
        ? 'На сегодня хватит! Приходи завтра.'
        : lim > 0
            ? 'Сегодня можно ещё $left ${plural(left, 'урок', 'урока', 'уроков')}.'
            : 'Выбери, чем займёмся!';
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
      children: [
        _hero(k, hello),
        if (stop)
          KidPanel(
            padding: const EdgeInsets.all(26),
            child: Column(children: [
              Text('Ты сегодня молодец!', textAlign: TextAlign.center, style: hd(26)),
              const SizedBox(height: 10),
              const Text('Отдохни, а завтра мы вместе выучим что-то новое.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: kKidText)),
            ]),
          )
        else ...[
          if (cont != null) _continueCard(context, cont),
          if (rec.isNotEmpty) ...[
            const KidSection(Si.clock, 'Недавно смотрели'),
            SizedBox(
              height: 262,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.only(bottom: 10),
                itemCount: rec.length,
                itemBuilder: (c, i) => _recentCard(c, rec[i]),
              ),
            ),
          ],
          const KidSection(Si.book, 'Курсы'),
          if (app.visibleCourses.isEmpty)
            const KidPanel(child: Text('Курсов пока нет.')),
          for (var i = 0; i < app.visibleCourses.length; i++)
            _courseCard(context, app.visibleCourses[i], i),
        ],
        const KidSection(Si.trophy, 'Мои награды'),
        const BadgesGrid(),
      ],
    );
  }

  /// Приветствие: аватарка, облачко и живой мишка на сцене.
  Widget _hero(Map<String, dynamic> k, String hello) {
    final art = app.equippedArt('bg');
    final scene = sceneIds.contains(art) ? art : 'meadow';
    return Container(
      margin: const EdgeInsets.only(top: 4),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFBFE6FF),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white, width: 6),
        boxShadow: kidShadow(9, 0.1),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Avatar(
              url: asStr(k['avatar_url']),
              name: asStr(k['name']),
              color: asStr(k['color']),
              size: 66,
              frame: app.equippedArt('frame'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), offset: Offset(0, 5)),
                  ],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Привет, ${asStr(k['name'])}!',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: hd(24)),
                  const SizedBox(height: 2),
                  Text(hello,
                      style: const TextStyle(
                          fontSize: 15.5, height: 1.25, color: kKidText)),
                ]),
              ),
            ),
          ]),
        ),
        SizedBox(
          height: 210,
          child: SceneView.crop(
            key: ValueKey('hero-$scene'),
            id: scene,
            view: Rect.fromLTWH(0, 330, 1600, 570),
            overlays: [
              Positioned(
                left: 868,
                top: 488.5,
                width: 285,
                height: 399,
                child: MascotAnim(hat: app.equippedArt('hat'), height: 399),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _continueCard(BuildContext context, ContinueTarget c) {
    final resume = c.kind == 'resume';
    return GestureDetector(
      onTap: () => openLesson(context, asStr(c.lesson['id'])),
      child: KidPanel(
        padding: const EdgeInsets.all(14),
        border: Border.all(color: Colors.white, width: 4),
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE4FFEE), Colors.white]),
        child: Row(children: [
          Pulse(
            child: Container(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                color: kKidGreen,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: kKidGreenD, offset: Offset(0, 5))],
              ),
              child: const Ic(Si.play, color: Colors.white, size: 30, fill: true),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(resume ? 'Продолжим с того места, где остановился' : 'Следующий урок',
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: kKidGreenD)),
              const SizedBox(height: 2),
              Text(asStr(c.lesson['title']),
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: hd(21)),
              Text(
                  asStr(c.course['title']) +
                      (c.pos > 5 ? ' · ${fmtT(c.pos)}' : ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, color: kKidText)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _recentCard(BuildContext context, LessonRef r) {
    final i = app.courses.indexWhere((c) => c['id'] == r.course['id']);
    final col = kidColors[(i < 0 ? 0 : i) % kidColors.length];
    final done = asBool(r.prog?['completed']);
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: SizedBox(
        width: 190,
        child: PressCard(
          onTap: () => openLesson(context, asStr(r.lesson['id'])),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 104,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [col, kdark(col, 0.3)]),
              ),
              child: Stack(children: [
                Center(
                    child: Ic(iconFor(asStr(r.course['icon'])),
                        color: Colors.white, size: 50)),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))
                      ],
                    ),
                    child: Ic(Si.play, color: col, size: 16, fill: true),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Text(asStr(r.lesson['title']),
                maxLines: 2, overflow: TextOverflow.ellipsis, style: hd(17)),
            Text(asStr(r.course['title']),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: kKidText)),
            const Spacer(),
            done
                ? StarsRow(count: starsOf(r.prog?['stars']), size: 22)
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF0D6),
                        borderRadius: BorderRadius.circular(99)),
                    child: const Text('не закончен',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFA35A00))),
                  ),
          ]),
        ),
      ),
    );
  }

  Widget _courseCard(BuildContext context, Map<String, dynamic> c, int i) {
    final id = asStr(c['id']);
    final ls = app.ofCourse(id);
    final done = ls.where((l) => app.isDone(asStr(l['id']))).length;
    final pct = ls.isEmpty ? 0.0 : done / ls.length;
    final lock = !app.canAccess(id);
    Map<String, dynamic>? nx;
    for (final l in ls) {
      if (!app.isDone(asStr(l['id']))) {
        nx = l;
        break;
      }
    }
    final sub = lock
        ? 'Пока закрыто'
        : (ls.isNotEmpty && done >= ls.length)
            ? 'Всё пройдено!'
            : nx != null
                ? '${done > 0 ? 'Дальше' : 'Начнём'}: ${asStr(nx['title'])}'
                : 'Скоро будет';
    final col = kidColors[i % kidColors.length];
    final card = PressCard(
      onTap: () => openCourse(context, c),
      radius: BorderRadius.circular(30),
      shadow: kdark(col, 0.45),
      shadowDy: 8,
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [col, kdark(col, 0.28)]),
      child: Stack(children: [
        Row(children: [
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Color(0x14000000), offset: Offset(0, -4)),
              ],
            ),
            child: Ic(iconFor(asStr(c['icon'])), color: col, size: 44),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(c['title']),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: hd(23).copyWith(color: Colors.white)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 14,
                    color: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.35)),
              ),
              const SizedBox(height: 4),
              Text(
                  '$done из ${ls.length} ${plural(ls.length, 'урока', 'уроков', 'уроков')}',
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ]),
          ),
        ]),
        if (lock)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 34,
              height: 34,
              decoration:
                  const BoxDecoration(color: kKidInk, shape: BoxShape.circle),
              child: const Ic(Si.lock, color: Colors.white, size: 17),
            ),
          ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: lock ? kidGrey(card) : card,
    );
  }
}

// =====================================================================
//  Магазин наград
// =====================================================================
const Map<String, String> _kindTitle = {
  'bg': 'Фоны',
  'frame': 'Рамки',
  'hat': 'Наряды',
};

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildBar(context, title: 'Магазин наград'),
      body: Backdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final k = app.kid;
              if (k == null) return const Center(child: Text('Нет профиля'));
              return _body(context, k);
            },
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, Map<String, dynamic> k) {
    final eq = asMap(k['equipped']);
    final bal = app.balance;
    final tab = app.shopTab;
    final items = app.shopItems
        .where((i) => i['kind'] == tab && asBool(i['active']))
        .toList()
      ..sort((a, b) {
        final c = asInt(a['sort']).compareTo(asInt(b['sort']));
        return c != 0 ? c : asInt(a['price']).compareTo(asInt(b['price']));
      });
    bool has(Map<String, dynamic> i) =>
        asInt(i['price']) == 0 || app.owned.contains(asStr(i['id']));
    bool isOn(Map<String, dynamic> i) =>
        eq[i['kind']] == i['id'] ||
        (i['kind'] == 'bg' &&
            eq['bg'] == null &&
            i['art'] == 'meadow' &&
            asInt(i['price']) == 0);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
      children: [
        KidPanel(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFBFE6FF), Color(0xFFE7F6FF)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: MascotAnim(hat: app.equippedArt('hat'), height: 112),
            ),
            const SizedBox(width: 8),
            Avatar(
              url: asStr(k['avatar_url']),
              name: asStr(k['name']),
              color: asStr(k['color']),
              size: 52,
              frame: app.equippedArt('frame'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Магазин наград',
                    style: hd(20)),
                const Text('Покупай вещи за звёзды, которые зарабатываешь на уроках.',
                    style: TextStyle(fontSize: 12.5)),
                const SizedBox(height: 6),
                Chip2(Si.star,
                    'У тебя $bal ${plural(bal, 'звезда', 'звезды', 'звёзд')}'),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Wrap(spacing: 10, runSpacing: 10, children: [
            for (final e in _kindTitle.entries)
              PressCard(
                onTap: () => app.setShopTab(e.key),
                color: tab == e.key ? kKidYellow : Colors.white,
                shadow: const Color(0x1F000000),
                shadowDy: 5,
                radius: BorderRadius.circular(99),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                child: Text(e.value,
                    style: hd(17).copyWith(
                        color: tab == e.key ? kKidYellowInk : kKidInk)),
              ),
          ]),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          const KidPanel(child: Text('Здесь пока пусто.')),
        LayoutBuilder(builder: (context, c) {
          final w = (c.maxWidth - 12) / 2;
          return Wrap(spacing: 12, runSpacing: 12, children: [
            for (final it in items)
              SizedBox(
                width: w,
                child: _item(context, k, it, bal, has(it), isOn(it)),
              ),
          ]);
        }),
      ],
    );
  }

  Widget _preview(Map<String, dynamic> k, Map<String, dynamic> it) {
    final art = asStr(it['art']);
    switch (asStr(it['kind'])) {
      case 'bg':
        return AspectRatio(aspectRatio: 1.6, child: SceneThumb(art: art));
      case 'frame':
        return SizedBox(
          height: 96,
          child: Center(
            child: Avatar(
              url: asStr(k['avatar_url']),
              name: asStr(k['name']),
              color: asStr(k['color']),
              size: 60,
              frame: art,
            ),
          ),
        );
      default:
        return SizedBox(
            height: 96, child: Center(child: Mascot(hat: art, height: 92, tight: true)));
    }
  }

  Widget _item(BuildContext context, Map<String, dynamic> k, Map<String, dynamic> it,
      int bal, bool own, bool on) {
    final price = asInt(it['price']);
    final kind = asStr(it['kind']);
    final id = asStr(it['id']);
    Widget action;
    if (on) {
      action = Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Ic(Si.checkc, color: Color(0xFF2E7D4F), size: 18),
          SizedBox(width: 4),
          Text('Надето', style: TextStyle(fontWeight: FontWeight.w800)),
        ]),
        if (kind != 'bg')
          TextButton(
            onPressed: () => _run(context, () => app.equip(kind, '')),
            child: const Text('Снять'),
          ),
      ]);
    } else if (own) {
      action = FilledButton(
        style: FilledButton.styleFrom(backgroundColor: kKidGreen),
        onPressed: () => _run(context, () => app.equip(kind, id)),
        child: const Text('Надеть'),
      );
    } else {
      action = FilledButton.icon(
        style: FilledButton.styleFrom(
            backgroundColor: bal < price ? const Color(0xFFCFD6E4) : kKidYellow,
            foregroundColor: kKidYellowInk),
        onPressed: () => _buy(context, it, bal),
        icon: const Ic(Si.star, size: 18),
        label: Text('$price'),
      );
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: kidShadow(8, 0.1),
        border: Border.all(
            color: on ? kKidGreen : Colors.transparent, width: 4),
      ),
      child: Column(children: [
        _preview(k, it),
        const SizedBox(height: 6),
        Text(asStr(it['title']),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        SizedBox(width: double.infinity, child: action),
      ]),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      if (context.mounted) toast(context, _rpcMsg(e), err: true);
    }
  }

  String _rpcMsg(Object e) {
    final m = e.toString();
    final i = m.indexOf('message:');
    if (i >= 0) {
      final rest = m.substring(i + 8);
      final j = rest.indexOf(',');
      return (j > 0 ? rest.substring(0, j) : rest).trim();
    }
    return errText(e);
  }

  Future<void> _buy(BuildContext context, Map<String, dynamic> it, int bal) async {
    final price = asInt(it['price']);
    if (bal < price) {
      final d = price - bal;
      toast(context,
          'Не хватает $d ${plural(d, 'звезды', 'звёзд', 'звёзд')}. Проходи уроки — и скоро купишь!',
          err: true);
      return;
    }
    final ok = await confirmDialog(
      context,
      'Купить «${asStr(it['title'])}»?',
      'Это стоит $price ${plural(price, 'звезду', 'звезды', 'звёзд')}. У тебя останется ${bal - price}.',
      ok: 'Купить',
    );
    if (!ok || !context.mounted) return;
    try {
      await app.buy(asStr(it['id']));
      if (context.mounted) toast(context, 'Куплено! Теперь можно надеть.');
    } catch (e) {
      if (context.mounted) toast(context, _rpcMsg(e), err: true);
    }
  }
}
