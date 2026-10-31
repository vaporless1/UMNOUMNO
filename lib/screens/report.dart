import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import '../icons.dart';
import '../theme.dart';

/// Отчёт для родителя за 7 или 30 дней.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int days = 7;
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> children = [];
  String mailMsg = '';
  bool mailErr = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final r = await sb.rpc('weekly_report',
          params: {'p_parent': app.user!.id, 'p_days': days});
      if (!mounted) return;
      setState(() {
        children = rows(asMap(r)['children']);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = errText(e);
        loading = false;
      });
    }
  }

  Future<void> _mail() async {
    setState(() {
      sending = true;
      mailMsg = 'Отправляем…';
      mailErr = false;
    });
    try {
      await sb.functions.invoke('weekly-report', body: {});
      if (!mounted) return;
      setState(() {
        sending = false;
        mailMsg = 'Отчёт отправлен на ${app.user?.email ?? ''}';
        mailErr = false;
      });
    } catch (e) {
      if (!mounted) return;
      var t = e.toString();
      if (e is FunctionException) {
        t = asStr(e.details).isNotEmpty ? asStr(e.details) : t;
      }
      setState(() {
        sending = false;
        mailMsg =
            'Не удалось отправить: $t. Возможно, отправка писем ещё не настроена.';
        mailErr = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Отчёт за ${days == 7 ? 'неделю' : '$days дней'}'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 дней')),
                    ButtonSegment(value: 30, label: Text('30 дней')),
                  ],
                  selected: {days},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    setState(() => days = s.first);
                    _load();
                  },
                ),
                const Spacer(),
                FilledButton(
                  onPressed: sending ? null : _mail,
                  child: const Text('На почту'),
                ),
              ]),
              MsgText(mailMsg, err: mailErr, ok: !mailErr && mailMsg.isNotEmpty),
            ]),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (error != null) Box(child: MsgText('Не удалось загрузить отчёт: $error', err: true)),
          if (!loading && error == null && children.isEmpty)
            const Box(child: Muted('Добавьте ребёнка, и здесь появится отчёт.', size: 14)),
          for (final c in children) _child(c),
        ],
      ),
    );
  }

  Widget _child(Map<String, dynamic> c) {
    final ls = rows(c['lessons']);
    final nums = asMap(c['nums']);
    final badges = asList(c['badges']).map((e) => asStr(e)).toList();
    final stars = ls.fold<int>(0, (s, x) => s + asInt(x['stars']));
    return Box(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${asStr(c['name'])}, ${ageT(asInt(c['age']))}',
            style: hd(18)),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, cc) {
          final w = (cc.maxWidth - 10) / 2;
          final items = <List<String>>[
            ['${ls.length}', 'уроков за период'],
            ['$stars', 'звёзд'],
            ['${asInt(nums['streak'])}', 'дней подряд'],
            ['${asInt(nums['lessons'])}', 'уроков всего'],
          ];
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final it in items)
              Container(
                width: w,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F2EC),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it[0],
                      style: hd(22)),
                  Text(it[1],
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ]),
              ),
          ]);
        }),
        const SizedBox(height: 12),
        if (ls.isEmpty) const Muted('За этот период занятий не было.', size: 14),
        for (final x in ls)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 2, right: 8),
                child: Ic(Si.checkc, size: 18),
              ),
              Expanded(
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: asStr(x['lesson']),
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  TextSpan(
                      text:
                          ' (${asStr(x['course'])}) — ${asInt(x['total']) > 0 ? '${asInt(x['score'])} из ${asInt(x['total'])}' : 'просмотрен'}, ${'★' * asInt(x['stars'])} · ${fd(x['at'])}'),
                ])),
              ),
            ]),
          ),
        if (badges.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text.rich(TextSpan(children: [
              const TextSpan(
                  text: 'Новые награды: ',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              TextSpan(text: badges.join(', ')),
            ])),
          ),
      ]),
    );
  }
}
