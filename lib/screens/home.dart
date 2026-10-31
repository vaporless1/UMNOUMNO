import 'package:flutter/material.dart';

import '../art.dart';
import '../kidui.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import 'kid_editor.dart';
import 'lesson.dart';
import 'report.dart';
import 'settings.dart';
import '../icons.dart';
import '../theme.dart';

// =====================================================================
//  Общие куски для родительского и детского экранов
// =====================================================================
class BadgesGrid extends StatelessWidget {
  const BadgesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    if (app.kidMode) return _kidShelf();
    if (app.badgesCat.isEmpty) return const Muted('Наград пока нет.');
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 20) / 3;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final b in app.badgesCat)
            Builder(builder: (context) {
              final on = app.earned.containsKey(asStr(b['id']));
              return Opacity(
                opacity: on ? 1 : 0.45,
                child: Container(
                  width: w,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFFFFF6D6) : const Color(0xFFF0EFEE),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(children: [
                    Ic(iconFor(asStr(b['icon'])),
                        size: 30,
                        color: on ? const Color(0xFFF5B301) : Colors.black45),
                    const SizedBox(height: 4),
                    Text(asStr(b['title']),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
                    Text(
                        on
                            ? fd(app.earned[asStr(b['id'])])
                            : asStr(b['description']),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
                  ]),
                ),
              );
            }),
        ],
      );
    });
  }

  /// Полка наград для ребёнка: крупные карточки, как на сайте.
  Widget _kidShelf() {
    if (app.badgesCat.isEmpty) {
      return const KidPanel(child: Text('Наград пока нет.'));
    }
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth >= 560 ? 3 : 2;
      final w = (c.maxWidth - 14 * (cols - 1)) / cols;
      return Wrap(
        spacing: 14,
        runSpacing: 16,
        children: [
          for (final b in app.badgesCat)
            Builder(builder: (context) {
              final on = app.earned.containsKey(asStr(b['id']));
              return Container(
                width: w,
                padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
                decoration: BoxDecoration(
                  color: on ? Colors.white : const Color(0xFFEEF2F9),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: kidShadow(7, on ? 0.1 : 0.06),
                ),
                child: Column(children: [
                  Container(
                    width: 66,
                    height: 66,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: on
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFD93D), Color(0xFFFF9F43)])
                          : null,
                      color: on ? null : const Color(0xFFCFD6E4),
                    ),
                    child: Ic(iconFor(asStr(b['icon'])),
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 10),
                  Text(asStr(b['title']),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: on ? kKidInk : const Color(0xFF6B7A99))),
                  const SizedBox(height: 4),
                  Text(
                      on ? fd(app.earned[asStr(b['id'])]) : asStr(b['description']),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, height: 1.25, color: kKidText)),
                ]),
              );
            }),
        ],
      );
    });
  }
}

class StatTiles extends StatelessWidget {
  const StatTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final streak = asInt(app.stats['streak']);
    final items = <List<dynamic>>[
      [Si.star, '${asInt(app.stats['stars'])}', 'звёзд'],
      [Si.book, '${asInt(app.stats['lessons'])}', 'уроков пройдено'],
      [
        Si.flame,
        '$streak',
        plural(streak, 'день', 'дня', 'дней') + ' подряд'
      ],
      [
        Si.trophy,
        '${app.earned.length}',
        'наград из ${app.badgesCat.length}'
      ],
    ];
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final it in items)
            Container(
              width: w,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2EC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(children: [
                Ic(it[0] as SIcon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(it[1] as String,
                        style: hd(20)),
                    Text(it[2] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, color: Colors.black54)),
                  ]),
                ),
              ]),
            ),
        ],
      );
    });
  }
}

void openCourse(BuildContext context, Map<String, dynamic> c) {
  if (app.active == null) {
    toast(context, 'Сначала добавьте ребёнка — прогресс сохраняется для него.',
        err: true);
    return;
  }
  if (!app.canAccess(asStr(c['id']))) {
    toast(context, 'Этот курс пока закрыт. Напишите нам, чтобы открыть доступ.',
        err: true);
    return;
  }
  Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CourseScreen(courseId: asStr(c['id']))));
}

void openLesson(BuildContext context, String id) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => LessonScreen(lessonId: id)));
}

// =====================================================================
//  Главный экран родителя
// =====================================================================
class ParentHome extends StatelessWidget {
  const ParentHome({super.key});

  Future<void> _refresh() async {
    try {
      await app.loadMe();
      await app.loadCatalog();
      await app.reloadAll();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final k = app.kid;
        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface),
                children: [
                  const TextSpan(text: 'УМ'),
                  TextSpan(
                      text: 'НО',
                      style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ],
              ),
            ),
            actions: [
              if (app.kids.isNotEmpty)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12)),
                  onPressed: () => startKidFlow(context),
                  icon: const Ic(Si.baby, size: 18),
                  label: const Text('Режим ребёнка'),
                ),
              IconButton(
                tooltip: 'Профиль и настройки',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
                icon: Avatar(
                    url: asStr(app.me['avatar_url']),
                    name: app.myName,
                    size: 32),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text('Привет, ${app.myName}!',
                      style: hd(26)),
                ),
                const SizedBox(height: 4),
                k != null
                    ? Text.rich(TextSpan(children: [
                        const TextSpan(text: 'Сейчас занимается: '),
                        TextSpan(
                            text: asStr(k['name']),
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        TextSpan(text: ', ${ageT(asInt(k['age']))}.'),
                      ]))
                    : const Text(
                        'Добавьте ребёнка — и мы подготовим для него занятия.'),
                _kidsBox(context),
                if (k != null) _kidBox(context, k),
                Box(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const H2('Курсы'),
                    if (app.visibleCourses.isEmpty) const Muted('Курсов пока нет.'),
                    for (final c in app.visibleCourses) CourseCard(course: c),
                  ]),
                ),
                const SizedBox(height: 8),
                const Center(child: DocLinks()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _kidsBox(BuildContext context) {
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const H2('Мои дети'),
        if (app.kids.isEmpty) const Muted('Пока никого нет.'),
        for (final c in app.kids)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: c['id'] == app.active
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : const Color(0xFFF7F2EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: c['id'] == app.active
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2),
            ),
            child: ListTile(
              onTap: () => app.selectKid(asStr(c['id'])),
              leading: Avatar(
                  url: asStr(c['avatar_url']),
                  name: asStr(c['name']),
                  color: asStr(c['color']),
                  size: 42),
              title: Text(asStr(c['name']),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(
                  '${asStr(c['username']).isNotEmpty ? '@${asStr(c['username'])} · ' : ''}${ageT(asInt(c['age']))}'),
              trailing: IconButton(
                tooltip: 'Редактировать',
                icon: const Ic(Si.edit),
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => KidEditorScreen(kid: c))),
              ),
            ),
          ),
        const SizedBox(height: 4),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const KidEditorScreen(kid: null))),
          icon: const Ic(Si.plus),
          label: const Text('Добавить ребёнка'),
        ),
      ]),
    );
  }

  Widget _kidBox(BuildContext context, Map<String, dynamic> k) {
    final recent = app.recentLessons(4);
    final lim = asInt(k['daily_limit']);
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(
              url: asStr(k['avatar_url']),
              name: asStr(k['name']),
              color: asStr(k['color']),
              size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(asStr(k['name']),
                  style: hd(20)),
              Muted(
                  '${asStr(k['username']).isNotEmpty ? '@${asStr(k['username'])}' : 'Юзернейм не задан'}'
                  '${lim > 0 ? ' · лимит: $lim ${plural(lim, 'урок', 'урока', 'уроков')} в день' : ''}',
                  size: 13),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: () => startKidFlow(context),
            icon: const Ic(Si.baby, size: 18),
            label: const Text('Режим ребёнка'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const ReportScreen())),
            icon: const Ic(Si.chart, size: 18),
            label: const Text('Отчёт за неделю'),
          ),
        ]),
        const SizedBox(height: 14),
        const StatTiles(),
        if (recent.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Недавно смотрел',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final r in recent)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                dense: true,
                onTap: () => openLesson(context, asStr(r.lesson['id'])),
                leading: Ic(iconFor(asStr(r.course['icon']))),
                title: Text(asStr(r.lesson['title']),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                    '${asStr(r.course['title'])} · ${fd(r.view['last_at'])}'),
                trailing: asBool(r.prog?['completed'])
                    ? StarsRow(count: starsOf(r.prog?['stars']), size: 16)
                    : const Text('не закончен',
                        style: TextStyle(fontSize: 11, color: Colors.black54)),
              ),
            ),
        ],
        if (asInt(app.stats['spent']) > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Muted(
                'В магазине потрачено: ${asInt(app.stats['spent'])} ★. На счёте сейчас: ${app.balance} ★.'),
          ),
        const SizedBox(height: 16),
        const H2('Награды'),
        const BadgesGrid(),
      ]),
    );
  }
}

// =====================================================================
//  Карточка курса (родитель)
// =====================================================================
class CourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final id = asStr(course['id']);
    final ls = app.ofCourse(id);
    final done = ls.where((l) => app.isDone(asStr(l['id']))).length;
    final pct = ls.isEmpty ? 0.0 : done / ls.length;
    final lock = !app.canAccess(id);
    final primary = Theme.of(context).colorScheme.primary;
    return Opacity(
      opacity: lock ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F2EC),
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => openCourse(context, course),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Ic(iconFor(asStr(course['icon'])), color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(
                      child: Text(asStr(course['title']),
                          style: hd(17)),
                    ),
                    if (lock) const Ic(Si.lock, size: 18),
                  ]),
                  if (asStr(course['description']).isNotEmpty)
                    Text(asStr(course['description']),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                        value: app.active == null ? 0 : pct,
                        minHeight: 8,
                        backgroundColor: Colors.black12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      lock
                          ? 'Откроется после оформления подписки'
                          : ls.isEmpty
                              ? 'Уроки скоро появятся'
                              : app.active != null
                                  ? '$done из ${ls.length} ${plural(ls.length, 'урока', 'уроков', 'уроков')}'
                                  : '${ls.length} уроков',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// =====================================================================
//  Список уроков курса
// =====================================================================
class CourseScreen extends StatefulWidget {
  final String courseId;
  const CourseScreen({super.key, required this.courseId});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  @override
  void initState() {
    super.initState();
    if (app.limitReached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? course;
    for (final c in app.courses) {
      if (c['id'] == widget.courseId) course = c;
    }
    return Scaffold(
      appBar: buildBar(context, title: course == null ? 'Курс' : asStr(course['title'])),
      body: Backdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: app,
            builder: (context, _) {
              final ls = app.ofCourse(widget.courseId);
              Map<String, dynamic>? next;
              if (app.kidMode) {
                for (final l in ls) {
                  if (!app.isDone(asStr(l['id']))) {
                    next = l;
                    break;
                  }
                }
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 30),
                children: [
                  app.kidMode
                      ? KidPanel(
                          margin: const EdgeInsets.only(top: 8),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14, left: 4),
                                  child: Text(course == null ? 'Курс' : asStr(course['title']),
                                      style: hd(28)),
                                ),
                                if (ls.isEmpty) const Muted('Уроки скоро появятся.'),
                                for (var i = 0; i < ls.length; i++)
                                  _row(context, ls[i], i, identical(ls[i], next)),
                              ]),
                        )
                      : Box(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                H2(course == null ? 'Курс' : asStr(course['title'])),
                                if (ls.isEmpty) const Muted('Уроки скоро появятся.'),
                                for (var i = 0; i < ls.length; i++)
                                  _row(context, ls[i], i, identical(ls[i], next)),
                              ]),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _kidRow(BuildContext context, Map<String, dynamic> l, int i, bool isNext,
      bool done, Map<String, dynamic>? p) {
    final id = asStr(l['id']);
    final col = done ? kKidGreen : const Color(0xFF4F8EF7);
    final row = PressCard(
      onTap: () {
        if (app.limitReached && !done) {
          toast(context, 'На сегодня хватит! Приходи завтра.', err: true);
          return;
        }
        openLesson(context, id);
      },
      color: const Color(0xFFF3F7FF),
      shadow: const Color(0x141F2A44),
      shadowDy: 6,
      radius: BorderRadius.circular(26),
      border: isNext ? Border.all(color: kKidGreen, width: 4) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          child: done
              ? const Ic(Si.check, color: Colors.white, size: 24)
              : Text('${i + 1}', style: hd(21).copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                asStr(l['title']) + (asBool(l['published']) ? '' : ' (черновик)'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 17.5, height: 1.2, fontWeight: FontWeight.w900)),
            if (asInt(l['duration_min']) > 0)
              Text('${asInt(l['duration_min'])} мин',
                  style: const TextStyle(fontSize: 13.5, color: kKidText)),
          ]),
        ),
        const SizedBox(width: 6),
        if (isNext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: kKidGreen, borderRadius: BorderRadius.circular(99)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Ic(Si.play, color: Colors.white, size: 15, fill: true),
              SizedBox(width: 4),
              Text('Сюда!',
                  style: TextStyle(
                      color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900)),
            ]),
          )
        else if (p != null && done)
          StarsRow(count: starsOf(p['stars']), size: 22),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isNext ? Pulse(to: 1.03, child: row) : row,
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> l, int i, bool isNext) {
    final id = asStr(l['id']);
    final p = app.prog[id];
    final done = app.isDone(id);
    final primary = Theme.of(context).colorScheme.primary;
    if (app.kidMode) return _kidRow(context, l, i, isNext, done, p);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isNext ? primary.withOpacity(0.14) : const Color(0xFFF7F2EC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isNext ? primary : Colors.transparent, width: 2),
      ),
      child: ListTile(
        onTap: () {
          if (app.limitReached && !done) {
            toast(context, 'На сегодня хватит! Приходи завтра.', err: true);
            return;
          }
          openLesson(context, id);
        },
        leading: CircleAvatar(
          backgroundColor: done ? const Color(0xFF4CAF7D) : primary,
          foregroundColor: Colors.white,
          child: done ? const Ic(Si.check) : Text('${i + 1}'),
        ),
        title: Text(
            asStr(l['title']) + (asBool(l['published']) ? '' : ' (черновик)'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: asInt(l['duration_min']) > 0
            ? Text('${asInt(l['duration_min'])} мин')
            : null,
        trailing: isNext
            ? Row(mainAxisSize: MainAxisSize.min, children: [
                Ic(Si.play, color: primary),
                Text('Сюда!', style: TextStyle(color: primary, fontWeight: FontWeight.w800)),
              ])
            : (p != null && done
                ? StarsRow(count: starsOf(p['stars']), size: 17)
                : null),
      ),
    );
  }
}
