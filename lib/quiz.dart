import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art.dart';
import 'state.dart';
import 'util.dart';
import 'voice.dart';
import 'widgets.dart';
import 'icons.dart';
import 'kidui.dart';
import 'theme.dart';

const List<String> _praise = ['Молодец!', 'Верно!', 'Отлично!', 'Умница!', 'Так держать!'];
const List<String> _tryAgain = ['Почти!', 'Попробуем ещё!', 'Не страшно!'];
final Random _rnd = Random();

String _pick(List<String> a) => a[_rnd.nextInt(a.length)];

String norm(String s) => s
    .toLowerCase()
    .replaceAll('ё', 'е')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Map<String, dynamic> opt(dynamic o) => o is String ? {'t': o} : asMap(o);

int starsFor(int s, int t) {
  if (t == 0) return 1;
  if (s >= t) return 3;
  if (s * 2 >= t) return 2;
  return 1;
}

List<String> taskParts(Map<String, dynamic> t) {
  final type = asStr(t['type']).isEmpty ? 'choice' : asStr(t['type']);
  final names = asList(t['options'])
      .map((o) => asStr(opt(o)['t']))
      .where((x) => x.isNotEmpty)
      .toList();
  final p = <String>[asStr(t['question'])];
  switch (type) {
    case 'choice':
      p.addAll(names);
      break;
    case 'multi':
      p.add('Выбери все подходящие ответы.');
      p.addAll(names);
      break;
    case 'text':
      p.add('Напиши ответ.');
      break;
    case 'word':
      p.add('Составь слово из букв.');
      break;
    case 'match':
      p.add('Соедини пары. Нажми на картинку слева, потом на пару справа.');
      break;
    case 'draw':
      p.add('Обведи букву пальцем.');
      break;
  }
  return p;
}

typedef TaskDone = void Function(bool ok, String extra);

// =====================================================================
//  Прохождение набора заданий
// =====================================================================
class QuizRunner extends StatefulWidget {
  final List<Map<String, dynamic>> tasks;
  final Future<List<Map<String, dynamic>>> Function(int score, int total) onFinish;
  final Widget Function(BuildContext context, int stars) actions;
  final ValueChanged<bool> onDrawing;

  const QuizRunner({
    super.key,
    required this.tasks,
    required this.onFinish,
    required this.actions,
    required this.onDrawing,
  });

  @override
  State<QuizRunner> createState() => _QuizRunnerState();
}

class _QuizRunnerState extends State<QuizRunner> {
  int i = 0;
  int score = 0;
  late List<bool?> res;
  bool answered = false;
  bool lastOk = false;
  String fbWord = '';
  String fbExtra = '';
  bool finished = false;
  bool saving = false;
  String? saveErr;
  List<Map<String, dynamic>> newBadges = [];

  Map<String, dynamic> get task => widget.tasks[i];

  @override
  void initState() {
    super.initState();
    res = List<bool?>.filled(widget.tasks.length, null);
    _speakTask();
  }

  @override
  void dispose() {
    Voice.stop();
    super.dispose();
  }

  void _speakTask() {
    if (app.voicePref && !finished) Voice.speak(taskParts(task));
  }

  void _done(bool ok, String extra) {
    if (answered) return;
    HapticFeedback.lightImpact();
    final w = _pick(ok ? _praise : _tryAgain);
    setState(() {
      answered = true;
      lastOk = ok;
      fbWord = w;
      fbExtra = extra;
      res[i] = ok;
      if (ok) score++;
    });
    if (app.voicePref) {
      Voice.speak([w, asStr(task['explanation']), extra]);
    }
  }

  void _next() {
    if (i + 1 >= widget.tasks.length) {
      _end();
    } else {
      setState(() {
        i++;
        answered = false;
        fbWord = '';
        fbExtra = '';
      });
      _speakTask();
    }
  }

  Future<void> _end() async {
    final total = widget.tasks.length;
    setState(() {
      finished = true;
      saving = true;
    });
    if (app.voicePref) {
      Voice.speak(['Урок пройден!', 'Ты правильно ответил на $score из $total.']);
    }
    try {
      final b = await widget.onFinish(score, total);
      if (!mounted) return;
      setState(() {
        newBadges = b;
        saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        saveErr = errText(e);
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) => finished ? _endView(context) : _taskView(context),
    );
  }

  Widget _dots() {
    final primary = Theme.of(context).colorScheme.primary;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var k = 0; k < widget.tasks.length; k++)
          Container(
            width: app.kidMode ? 18 : 12,
            height: app.kidMode ? 18 : 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: k < i
                  ? (res[k] == true ? const Color(0xFF2FBF71) : const Color(0xFFFF5A5F))
                  : k == i
                      ? (app.kidMode ? const Color(0xFF4F8EF7) : primary)
                      : (app.kidMode ? Colors.white : Colors.black12),
            ),
          ),
      ],
    );
  }

  Widget _taskView(BuildContext context) {
    final t = task;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          IconButton.filledTonal(
            tooltip: 'Послушать задание',
            icon: const Ic(Si.sound),
            onPressed: () => Voice.speak(taskParts(t)),
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text('авто'),
            avatar: Ic(app.voicePref ? Si.sound : Si.mute, size: 18),
            selected: app.voicePref,
            onSelected: (v) {
              app.setVoicePref(v);
              if (v) {
                Voice.speak(taskParts(t));
              } else {
                Voice.stop();
              }
            },
          ),
        ]),
        const SizedBox(height: 8),
        _dots(),
        const SizedBox(height: 16),
        if (asStr(t['image_url']).isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(asStr(t['image_url']),
                  height: 180, fit: BoxFit.contain, cacheHeight: 540,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
          ),
        Text(asStr(t['question']),
            textAlign: TextAlign.center,
            style: hd(app.kidMode ? 30 : 22).copyWith(height: 1.2)),
        const SizedBox(height: 16),
        TaskView(
          key: ValueKey('task$i'),
          task: t,
          onDone: _done,
          onDrawing: widget.onDrawing,
        ),
        if (answered) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: lastOk ? const Color(0xFFDFF5E6) : const Color(0xFFFBE0DC),
              borderRadius: BorderRadius.circular(app.kidMode ? 26 : 18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(fbWord,
                  style: TextStyle(
                      fontSize: app.kidMode ? 26 : 20,
                      fontWeight: app.kidMode ? FontWeight.w900 : FontWeight.w800,
                      color: lastOk ? const Color(0xFF1E6B3F) : const Color(0xFF9B2C20))),
              if (asStr(t['explanation']).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(asStr(t['explanation'])),
                ),
              if (fbExtra.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(fbExtra),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            onPressed: _next,
            child: Text(i + 1 < widget.tasks.length ? 'Дальше' : 'Готово',
                style: const TextStyle(fontSize: 17)),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _endView(BuildContext context) {
    final total = widget.tasks.length;
    final st = starsFor(score, total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Text('Урок пройден!',
            textAlign: TextAlign.center,
            style: hd(26)),
        const SizedBox(height: 14),
        Center(child: StarsRow(count: st, size: app.kidMode ? 84 : 56)),
        const SizedBox(height: 10),
        Text('Верно: $score из $total',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 10),
        if (saving) const Center(child: Muted('Сохраняем результат…')),
        if (saveErr != null) Center(child: MsgText('Не удалось сохранить: $saveErr', err: true)),
        for (final b in newBadges)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF5E6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Ic(iconFor(asStr(b['icon'])), color: const Color(0xFF1E6B3F)),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Новая награда: ${asStr(b['title'])}',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        const SizedBox(height: 18),
        widget.actions(context, st),
        const SizedBox(height: 24),
      ],
    );
  }
}

// =====================================================================
//  Плитка варианта ответа
// =====================================================================
class OptTile extends StatelessWidget {
  final Map<String, dynamic> o;
  final String state; // '', sel, good, bad, used
  final VoidCallback? onTap;
  final Color? accent;
  final double? width;
  final bool big;

  const OptTile({
    super.key,
    required this.o,
    this.state = '',
    this.onTap,
    this.accent,
    this.width,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Color bg = const Color(0xFFF0EFEE);
    Color border = Colors.transparent;
    switch (state) {
      case 'sel':
        bg = Colors.white;
        border = primary;
        break;
      case 'good':
        bg = const Color(0xFFDFF5E6);
        border = const Color(0xFF2E7D4F);
        break;
      case 'bad':
        bg = const Color(0xFFFBE0DC);
        border = const Color(0xFFC0392B);
        break;
    }
    if (accent != null && state != 'good' && state != 'bad') {
      border = accent!;
    }
    final img = asStr(o['img']);
    final txt = asStr(o['t']);
    if (app.kidMode) return _kidTile(this, img, txt);
    final tile = Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: width,
          constraints: BoxConstraints(minHeight: big ? 64 : 58),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 2.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (img.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: txt.isEmpty ? 0 : 6),
                  child: Image.network(img,
                      height: 90,
                      cacheHeight: 270,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Ic(Si.noimg)),
                ),
              if (txt.isNotEmpty)
                Text(txt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: big ? 24 : 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
    return state == 'used' ? Opacity(opacity: 0.3, child: tile) : tile;
  }
}

Widget _kidTile(OptTile t, String img, String txt) {
    Color bg = Colors.white, line = const Color(0xFFE4EBFB), sh = const Color(0xFFCDD8F1);
    switch (t.state) {
      case 'sel':
        bg = const Color(0xFFE9F1FF);
        line = const Color(0xFF4F8EF7);
        break;
      case 'good':
        bg = const Color(0xFFE5FBEF);
        line = const Color(0xFF2FBF71);
        sh = const Color(0xFFA7E5C4);
        break;
      case 'bad':
        bg = const Color(0xFFFFECEC);
        line = const Color(0xFFFF5A5F);
        sh = const Color(0xFFFFC2C4);
        break;
    }
    if (t.accent != null && t.state != 'good' && t.state != 'bad') line = t.accent!;
    final tile = SizedBox(
      width: t.width,
      child: PressCard(
        onTap: t.onTap,
        color: bg,
        shadow: sh,
        shadowDy: 7,
        radius: BorderRadius.circular(26),
        border: Border.all(color: line, width: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: t.big ? 70 : 62),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (img.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: txt.isEmpty ? 0 : 6),
                  child: Image.network(img,
                      height: 100,
                      cacheHeight: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Ic(Si.noimg)),
                ),
              if (txt.isNotEmpty)
                Text(txt,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: t.big ? 30 : 24,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                        color: kKidInk)),
            ],
          ),
        ),
      ),
    );
    return t.state == 'used' ? Opacity(opacity: 0.3, child: tile) : tile;
  }

/// Сетка вариантов в два столбца.
class OptGrid extends StatelessWidget {
  final List<Widget Function(double width)> builders;
  const OptGrid({super.key, required this.builders});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [for (final b in builders) b(w)],
      );
    });
  }
}

Widget _checkBtn(String label, bool enabled, VoidCallback onTap) => Padding(
      padding: const EdgeInsets.only(top: 14),
      child: FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
        onPressed: enabled ? onTap : null,
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );

// =====================================================================
//  Одно задание (выбор по типу)
// =====================================================================
class TaskView extends StatelessWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  final ValueChanged<bool> onDrawing;

  const TaskView({
    super.key,
    required this.task,
    required this.onDone,
    required this.onDrawing,
  });

  @override
  Widget build(BuildContext context) {
    final type = asStr(task['type']).isEmpty ? 'choice' : asStr(task['type']);
    switch (type) {
      case 'multi':
        return MultiTask(task: task, onDone: onDone);
      case 'text':
        return TextTask(task: task, onDone: onDone);
      case 'word':
        return WordTask(task: task, onDone: onDone);
      case 'match':
        return MatchTask(task: task, onDone: onDone);
      case 'draw':
        return DrawTask(task: task, onDone: onDone, onDrawing: onDrawing);
      default:
        return ChoiceTask(task: task, onDone: onDone);
    }
  }
}

// ---------- выбор одного ответа ----------
class ChoiceTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  const ChoiceTask({super.key, required this.task, required this.onDone});

  @override
  State<ChoiceTask> createState() => _ChoiceTaskState();
}

class _ChoiceTaskState extends State<ChoiceTask> {
  int? picked;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    final os = asList(widget.task['options']).map(opt).toList();
    final correct = asInt(widget.task['correct']);
    String st(int i) {
      if (!done) return '';
      if (i == correct) return 'good';
      if (i == picked) return 'bad';
      return '';
    }

    return OptGrid(builders: [
      for (var i = 0; i < os.length; i++)
        (double w) => OptTile(
              o: os[i],
              width: w,
              state: st(i),
              big: asStr(os[i]['t']).length <= 2 && asStr(os[i]['img']).isEmpty,
              onTap: done
                  ? null
                  : () {
                      setState(() {
                        done = true;
                        picked = i;
                      });
                      widget.onDone(i == correct, '');
                    },
            ),
    ]);
  }
}

// ---------- выбор нескольких ----------
class MultiTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  const MultiTask({super.key, required this.task, required this.onDone});

  @override
  State<MultiTask> createState() => _MultiTaskState();
}

class _MultiTaskState extends State<MultiTask> {
  final Set<int> sel = {};
  bool done = false;

  @override
  Widget build(BuildContext context) {
    final os = asList(widget.task['options']).map(opt).toList();
    final right = asList(asMap(widget.task['data'])['correct']).map(asInt).toSet();
    String st(int i) {
      if (!done) return sel.contains(i) ? 'sel' : '';
      if (right.contains(i)) return 'good';
      if (sel.contains(i)) return 'bad';
      return '';
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: Muted('Выбери все подходящие ответы')),
      const SizedBox(height: 10),
      OptGrid(builders: [
        for (var i = 0; i < os.length; i++)
          (double w) => OptTile(
                o: os[i],
                width: w,
                state: st(i),
                onTap: done
                    ? null
                    : () => setState(() {
                          if (!sel.remove(i)) sel.add(i);
                        }),
              ),
      ]),
      if (!done)
        _checkBtn('Проверить', sel.isNotEmpty, () {
          final ok = sel.length == right.length && sel.every(right.contains);
          setState(() => done = true);
          widget.onDone(ok, '');
        }),
    ]);
  }
}

// ---------- ввод текста ----------
class TextTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  const TextTask({super.key, required this.task, required this.onDone});

  @override
  State<TextTask> createState() => _TextTaskState();
}

class _TextTaskState extends State<TextTask> {
  final TextEditingController ctrl = TextEditingController();
  bool done = false;
  bool? ok;

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  void _check() {
    if (done || norm(ctrl.text).isEmpty) return;
    final answers = asList(asMap(widget.task['data'])['answers']).map(asStr).toList();
    final good = answers.any((a) => norm(a) == norm(ctrl.text));
    FocusScope.of(context).unfocus();
    setState(() {
      done = true;
      ok = good;
    });
    widget.onDone(good, good || answers.isEmpty ? '' : 'Правильный ответ: ${answers.first}');
  }

  @override
  Widget build(BuildContext context) {
    final color = ok == null
        ? null
        : ok == true
            ? const Color(0xFF2E7D4F)
            : const Color(0xFFC0392B);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: ctrl,
        enabled: !done,
        autocorrect: false,
        enableSuggestions: false,
        textAlign: TextAlign.center,
        textInputAction: TextInputAction.done,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Напиши ответ',
          enabledBorder: color == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: color, width: 2.5)),
          disabledBorder: color == null
              ? null
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: color, width: 2.5)),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _check(),
      ),
      if (!done) _checkBtn('Проверить', norm(ctrl.text).isNotEmpty, _check),
    ]);
  }
}

// ---------- составить слово ----------
class WordTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  const WordTask({super.key, required this.task, required this.onDone});

  @override
  State<WordTask> createState() => _WordTaskState();
}

class _WordTaskState extends State<WordTask> {
  late String word;
  late List<String> pool;
  final List<int> slots = [];
  List<String> cls = [];
  bool done = false;

  @override
  void initState() {
    super.initState();
    final d = asMap(widget.task['data']);
    word = asStr(d['word']).toUpperCase().replaceAll(RegExp(r'\s'), '');
    final extra = asStr(d['extra']).toUpperCase().replaceAll(RegExp(r'\s'), '');
    pool = (word + extra).split('')..shuffle(_rnd);
  }

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var k = 0; k < letters.length; k++)
            SizedBox(
              width: 54,
              child: OptTile(
                o: {'t': k < slots.length ? pool[slots[k]] : ''},
                big: true,
                state: done && k < cls.length ? cls[k] : (k < slots.length ? 'sel' : ''),
                onTap: (done || k >= slots.length)
                    ? null
                    : () => setState(() => slots.removeAt(k)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 18),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var p = 0; p < pool.length; p++)
            SizedBox(
              width: 58,
              child: OptTile(
                o: {'t': pool[p]},
                big: true,
                state: slots.contains(p) ? 'used' : '',
                onTap: (done || slots.contains(p) || slots.length >= letters.length)
                    ? null
                    : () => setState(() => slots.add(p)),
              ),
            ),
        ],
      ),
      if (!done)
        _checkBtn('Проверить', slots.length == letters.length, () {
          final got = slots.map((i) => pool[i]).toList();
          final ok = got.join() == word;
          setState(() {
            done = true;
            cls = [
              for (var k = 0; k < got.length; k++) got[k] == letters[k] ? 'good' : 'bad'
            ];
          });
          widget.onDone(ok, ok ? '' : 'Правильно: $word');
        }),
    ]);
  }
}

// ---------- соединить пары ----------
class MatchTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  const MatchTask({super.key, required this.task, required this.onDone});

  @override
  State<MatchTask> createState() => _MatchTaskState();
}

class _MatchTaskState extends State<MatchTask> {
  late List<Map<String, dynamic>> lefts;
  late List<Map<String, dynamic>> rights;
  late List<int> order;
  final Map<int, int> link = {};
  int? pend;
  bool graded = false;

  static const List<Color> _col = [
    Color(0xFF4F8EF7),
    Color(0xFFE0709A),
    Color(0xFF4CAF7D),
    Color(0xFFE8873A),
    Color(0xFF8A63D2),
    Color(0xFFD9B300),
    Color(0xFF17A2B8),
    Color(0xFF795548),
  ];

  @override
  void initState() {
    super.initState();
    final pairs = asList(asMap(widget.task['data'])['pairs']).map(asMap).toList();
    lefts = pairs.map((p) => opt(p['l'])).toList();
    rights = pairs.map((p) => opt(p['r'])).toList();
    order = List<int>.generate(pairs.length, (i) => i)..shuffle(_rnd);
  }

  @override
  Widget build(BuildContext context) {
    final owner = <int, int>{};
    link.forEach((l, r) => owner[r] = l);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Center(child: Muted('Нажми на картинку слева, потом на пару справа')),
      const SizedBox(height: 10),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(children: [
            for (var i = 0; i < lefts.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptTile(
                  o: lefts[i],
                  accent: link[i] != null ? _col[i % 8] : null,
                  state: graded
                      ? (link[i] == i ? 'good' : 'bad')
                      : (pend == i ? 'sel' : ''),
                  onTap: graded
                      ? null
                      : () => setState(() {
                            link.remove(i);
                            pend = i;
                          }),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(children: [
            for (final r in order)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OptTile(
                  o: rights[r],
                  accent: owner[r] != null ? _col[owner[r]! % 8] : null,
                  state: graded && owner[r] != null
                      ? (owner[r] == r ? 'good' : 'bad')
                      : '',
                  onTap: (graded || pend == null)
                      ? null
                      : () => setState(() {
                            link.removeWhere((k, v) => v == r);
                            link[pend!] = r;
                            pend = null;
                          }),
                ),
              ),
          ]),
        ),
      ]),
      if (!graded)
        _checkBtn('Проверить', link.length == lefts.length, () {
          final ok = List.generate(lefts.length, (i) => link[i] == i).every((x) => x);
          setState(() => graded = true);
          widget.onDone(ok, '');
        }),
    ]);
  }
}

// ---------- обвести букву ----------
class DrawTask extends StatefulWidget {
  final Map<String, dynamic> task;
  final TaskDone onDone;
  final ValueChanged<bool> onDrawing;
  const DrawTask(
      {super.key,
      required this.task,
      required this.onDone,
      required this.onDrawing});

  @override
  State<DrawTask> createState() => _DrawTaskState();
}

/// Одна линия рисунка: части внутри границ буквы и вне её хранятся отдельно,
/// чтобы выход за край сразу было видно красным.
class _Stroke {
  final List<Offset> pts = [];
  final Path ok = Path();
  final Path bad = Path();
}

/// Линии рисунка. Меняются без setState: перерисовывается только холст.
class _StrokeBook extends ChangeNotifier {
  final List<_Stroke> strokes = [];
  bool Function(Offset) inside = (_) => true;

  bool get isEmpty => strokes.isEmpty;

  double get length {
    double l = 0;
    for (final s in strokes) {
      for (var i = 1; i < s.pts.length; i++) {
        l += (s.pts[i] - s.pts[i - 1]).distance;
      }
    }
    return l;
  }

  void start(Offset o) {
    final s = _Stroke();
    s.pts.add(o);
    final path = inside(o) ? s.ok : s.bad;
    path.moveTo(o.dx, o.dy);
    path.lineTo(o.dx + 0.1, o.dy);
    strokes.add(s);
    notifyListeners();
  }

  void extend(Offset o) {
    if (strokes.isEmpty) return;
    final s = strokes.last;
    final a = s.pts.last;
    final path = inside(o) ? s.ok : s.bad;
    path.moveTo(a.dx, a.dy);
    path.lineTo(o.dx, o.dy);
    s.pts.add(o);
    notifyListeners();
  }

  void clear() {
    strokes.clear();
    notifyListeners();
  }
}

const double _kBrush = 14;
const double _kTol = 13;
const double _kHit = 0.7;
const double _kOut = 0.25;
const double _kScale = 0.5;

class _StrokePainter extends CustomPainter {
  final _StrokeBook book;
  final Color color;
  _StrokePainter(this.book, this.color) : super(repaint: book);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..strokeWidth = _kBrush
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final s in book.strokes) {
      canvas.drawPath(s.ok, p..color = color);
      canvas.drawPath(s.bad, p..color = const Color(0xFFD9534F));
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter old) => old.color != color;
}

/// Серая буква-подсказка. Рисуется тем же кодом, что и маска для проверки,
/// поэтому границы совпадают с тем, что видит ребёнок.
void _paintLetter(Canvas c, Size size, String letter, TextStyle base,
    {Color? color, double? outline}) {
  final fs = size.height * 0.72;
  TextPainter tp(TextStyle st) => TextPainter(
      text: TextSpan(text: letter, style: st), textDirection: TextDirection.ltr)
    ..layout();
  final fill = tp(base.copyWith(
      fontSize: fs, fontWeight: FontWeight.w900, height: 1.0, color: color ?? const Color(0xFF000000)));
  final off = Offset((size.width - fill.width) / 2, (size.height - fill.height) / 2);
  if (outline != null) {
    final st = tp(base.copyWith(
        fontSize: fs,
        fontWeight: FontWeight.w900,
        height: 1.0,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outline
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFF000000)));
    st.paint(c, off);
  }
  fill.paint(c, off);
}

class _GuidePainter extends CustomPainter {
  final String letter;
  final TextStyle base;
  _GuidePainter(this.letter, this.base);

  @override
  void paint(Canvas canvas, Size size) =>
      _paintLetter(canvas, size, letter, base, color: const Color(0xFFE3E3E3));

  @override
  bool shouldRepaint(covariant _GuidePainter old) =>
      old.letter != letter || old.base != base;
}

class _DrawTaskState extends State<DrawTask> {
  final _StrokeBook book = _StrokeBook();
  bool done = false;
  bool checking = false;
  int tries = 0;
  String hint = '';
  Size? _size;
  Uint8List? _letterM; // буква
  Uint8List? _allowM; // буква + допуск у краёв
  int _gw = 0, _gh = 0;

  @override
  void dispose() {
    book.dispose();
    widget.onDrawing(false);
    super.dispose();
  }

  Future<Uint8List> _alpha(void Function(Canvas) draw) async {
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.scale(_kScale);
    draw(c);
    final img = await rec.endRecording().toImage(_gw, _gh);
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    final src = bd!.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
    final out = Uint8List(_gw * _gh);
    for (var i = 0; i < out.length; i++) {
      out[i] = src[i * 4 + 3];
    }
    return out;
  }

  Future<void> _prepare(Size size, String letter, TextStyle base) async {
    _size = size;
    _gw = max(1, (size.width * _kScale).round());
    _gh = max(1, (size.height * _kScale).round());
    final l = await _alpha((c) => _paintLetter(c, size, letter, base));
    final a = await _alpha((c) => _paintLetter(c, size, letter, base, outline: _kTol * 2));
    if (!mounted) return;
    _letterM = l;
    _allowM = a;
    book.inside = (o) {
      final x = (o.dx * _kScale).floor(), y = (o.dy * _kScale).floor();
      if (x < 0 || y < 0 || x >= _gw || y >= _gh) return false;
      return a[y * _gw + x] > 40;
    };
  }

  /// Рисует линии в маску заданной толщины (в тех же координатах, что и буква).
  Future<Uint8List> _ink(double width) {
    return _alpha((c) {
      final p = Paint()
        ..color = const Color(0xFF000000)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (final s in book.strokes) {
        final path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
        if (s.pts.length == 1) path.lineTo(s.pts.first.dx + 0.1, s.pts.first.dy);
        for (final o in s.pts.skip(1)) {
          path.lineTo(o.dx, o.dy);
        }
        c.drawPath(path, p);
      }
    });
  }

  Future<void> _check(String letter) async {
    if (done || checking) return;
    if (_letterM == null || _allowM == null) return;
    if (book.isEmpty || book.length < 20) {
      setState(() => hint = 'Обведи пальцем серую букву');
      return;
    }
    checking = true;
    final narrow = await _ink(_kBrush);
    final wide = await _ink(_kBrush + _kTol * 2);
    checking = false;
    if (!mounted) return;
    final lm = _letterM!, am = _allowM!;
    var lt = 0, lc = 0, it = 0, io = 0;
    for (var i = 0; i < lm.length; i++) {
      if (lm[i] > 128) {
        lt++;
        if (wide[i] > 40) lc++;
      }
      if (narrow[i] > 40) {
        it++;
        if (am[i] <= 40) io++;
      }
    }
    final cover = lt == 0 ? 0.0 : lc / lt;
    final outside = it == 0 ? 1.0 : io / it;
    tries++;
    if (cover >= _kHit && outside <= _kOut) {
      setState(() {
        done = true;
        hint = '';
      });
      widget.onDone(true, '');
    } else if (tries >= 3) {
      setState(() {
        done = true;
        hint = '';
      });
      widget.onDone(false, 'Буква: $letter');
    } else {
      setState(() => hint = outside > _kOut
          ? 'Рисуй внутри серой буквы: красные линии вышли за край. Нажми «Стереть» и попробуй ещё.'
          : 'Обведи всю букву до конца: закрашено ${(cover * 100).round()}%.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final letter = asStr(asMap(widget.task['data'])['letter']).trim();
    final primary = Theme.of(context).colorScheme.primary;
    final ds = DefaultTextStyle.of(context).style;
    final base = TextStyle(fontFamily: ds.fontFamily, fontFamilyFallback: ds.fontFamilyFallback);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AspectRatio(
        aspectRatio: 1.15,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.black12, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(builder: (context, c) {
            final size = Size(c.maxWidth, c.maxHeight);
            if (_size != size && letter.isNotEmpty) {
              _size = size;
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _prepare(size, letter, base));
            }
            return Stack(children: [
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(painter: _GuidePainter(letter, base)),
                ),
              ),
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) {
                    if (done) return;
                    widget.onDrawing(true);
                    book.start(e.localPosition);
                  },
                  onPointerMove: (e) {
                    if (done) return;
                    book.extend(e.localPosition);
                  },
                  onPointerUp: (_) => widget.onDrawing(false),
                  onPointerCancel: (_) => widget.onDrawing(false),
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _StrokePainter(book, primary),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ]);
          }),
        ),
      ),
      if (hint.isNotEmpty) Center(child: MsgText(hint)),
      if (!done)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52)),
              onPressed: () {
                book.clear();
                setState(() => hint = '');
              },
              child: const Text('Стереть'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => _check(letter),
                child: const Text('Готово', style: TextStyle(fontSize: 16)),
              ),
            ),
          ]),
        ),
    ]);
  }
}
