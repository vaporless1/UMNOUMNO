import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../art.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';

/// Создание и редактирование профиля ребёнка.
class KidEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? kid;
  const KidEditorScreen({super.key, required this.kid});

  @override
  State<KidEditorScreen> createState() => _KidEditorScreenState();
}

class _KidEditorScreenState extends State<KidEditorScreen> {
  late final bool isNew;
  late final String id;
  final TextEditingController name = TextEditingController();
  final TextEditingController uname = TextEditingController();
  final TextEditingController about = TextEditingController();
  int age = 5;
  int limit = 0;
  String color = profileColors.first;
  String? avatar;
  final Set<String> hidden = {};
  bool consent = false;
  String unameMsg = '';
  bool unameOk = false;
  String msg = '';
  bool msgErr = false;
  bool busy = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final k = widget.kid;
    isNew = k == null;
    id = k == null ? uuid4() : asStr(k['id']);
    if (k != null) {
      name.text = asStr(k['name']);
      uname.text = asStr(k['username']).isEmpty ? '' : '@${asStr(k['username'])}';
      about.text = asStr(k['about']);
      age = asInt(k['age']) == 0 ? 5 : asInt(k['age']);
      limit = asInt(k['daily_limit']);
      final c = asStr(k['color']);
      if (c.isNotEmpty) color = c;
      avatar = asStr(k['avatar_url']).isEmpty ? null : asStr(k['avatar_url']);
      hidden.addAll(asList(k['hidden_courses']).map((e) => asStr(e)));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    name.dispose();
    uname.dispose();
    about.dispose();
    super.dispose();
  }

  void _unameChanged(String raw) {
    timer?.cancel();
    final v = cleanUname(raw);
    final own = asStr(widget.kid?['username']);
    if (v.isEmpty || v == own) {
      setState(() {
        unameMsg = '';
        unameOk = false;
      });
      return;
    }
    if (!unameRe.hasMatch(v)) {
      setState(() {
        unameMsg = '3–20 символов: латиница, цифры, _';
        unameOk = false;
      });
      return;
    }
    timer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final r = await sb.rpc('username_free', params: {'u': v});
        if (!mounted) return;
        setState(() {
          unameOk = r == true;
          unameMsg = r == true ? '@$v свободен' : '@$v уже занят';
        });
      } catch (_) {}
    });
  }

  Future<void> _pickPhoto() async {
    try {
      final x = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: 256,
          maxHeight: 256,
          imageQuality: 86);
      if (x == null) return;
      setState(() {
        msg = 'Загружаем фото…';
        msgErr = false;
      });
      final bytes = await x.readAsBytes();
      final path = '${app.user!.id}/child_$id.jpg';
      await sb.storage.from('avatars').uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url = sb.storage.from('avatars').getPublicUrl(path);
      if (!mounted) return;
      setState(() {
        avatar = '$url?v=${DateTime.now().millisecondsSinceEpoch}';
        msg = 'Фото загружено. Не забудьте сохранить.';
        msgErr = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        msg = 'Не удалось загрузить фото: ${errText(e)}';
        msgErr = true;
      });
    }
  }

  Future<void> _save() async {
    final n = name.text.trim();
    final un = cleanUname(uname.text);
    if (isNew && !consent) {
      setState(() {
        msg = 'Нужно согласие законного представителя на обработку данных ребёнка.';
        msgErr = true;
      });
      return;
    }
    if (n.isEmpty) {
      setState(() {
        msg = 'Введите имя';
        msgErr = true;
      });
      return;
    }
    if (un.isNotEmpty && !unameRe.hasMatch(un)) {
      setState(() {
        msg = 'Юзернейм: 3–20 символов, латиница, цифры и _';
        msgErr = true;
      });
      return;
    }
    final row = <String, dynamic>{
      'name': n,
      'age': age,
      'username': un.isEmpty ? null : un,
      'about': about.text.trim().isEmpty ? null : about.text.trim(),
      'color': color,
      'avatar_url': avatar,
      'daily_limit': limit,
      'hidden_courses': hidden.toList(),
    };
    setState(() {
      busy = true;
      msg = '';
    });
    try {
      if (isNew) {
        await sb.from('children').insert({'id': id, ...row});
      } else {
        await sb.from('children').update(row).eq('id', id);
      }
      app.active = id;
      await app.prefs?.setString('umno_kid', id);
      await app.reloadAll();
      if (!mounted) return;
      toast(context, isNew ? 'Профиль создан!' : 'Сохранено');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        busy = false;
        msg = errText(e);
        msgErr = true;
      });
    }
  }

  Future<void> _delete() async {
    final ok = await confirmDialog(
      context,
      'Удалить профиль «${name.text}»?',
      'Весь прогресс и награды тоже удалятся.',
      ok: 'Удалить',
    );
    if (!ok) return;
    try {
      await sb.from('children').delete().eq('id', id);
      await app.reloadAll();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        msg = errText(e);
        msgErr = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final courses = app.courses;
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Новый ребёнок' : 'Профиль ребёнка'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
        children: [
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Avatar(
                    url: avatar,
                    name: name.text.isEmpty ? '?' : name.text,
                    color: color,
                    size: 72),
                const SizedBox(width: 14),
                Wrap(spacing: 6, children: [
                  OutlinedButton(
                      onPressed: _pickPhoto, child: const Text('Загрузить фото')),
                  if (avatar != null)
                    TextButton(
                        onPressed: () => setState(() => avatar = null),
                        child: const Text('убрать')),
                ]),
              ]),
              const SizedBox(height: 14),
              TextField(
                controller: name,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Имя'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: age,
                decoration: const InputDecoration(labelText: 'Возраст'),
                items: [
                  for (var a = 2; a <= 12; a++)
                    DropdownMenuItem(value: a, child: Text(ageT(a))),
                ],
                onChanged: (v) => setState(() => age = v ?? age),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: uname,
                maxLength: 21,
                autocorrect: false,
                decoration:
                    const InputDecoration(labelText: '@юзернейм (необязательно)'),
                onChanged: _unameChanged,
              ),
              MsgText(unameMsg, ok: unameOk, err: !unameOk && unameMsg.isNotEmpty),
              TextField(
                controller: about,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'О ребёнке (любимое, увлечения)'),
              ),
              const SizedBox(height: 8),
              const Text('Цвет профиля',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 10, children: [
                for (final c in profileColors)
                  GestureDetector(
                    onTap: () => setState(() => color = c),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: hexColor(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color.toLowerCase() == c.toLowerCase()
                                ? Colors.black87
                                : Colors.transparent,
                            width: 3),
                      ),
                    ),
                  ),
              ]),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: const [0, 1, 2, 3, 5, 10].contains(limit) ? limit : 0,
                decoration: const InputDecoration(
                    labelText: 'Лимит: уроков в день (режим ребёнка)'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Без ограничений')),
                  DropdownMenuItem(value: 1, child: Text('1 урок')),
                  DropdownMenuItem(value: 2, child: Text('2 урока')),
                  DropdownMenuItem(value: 3, child: Text('3 урока')),
                  DropdownMenuItem(value: 5, child: Text('5 уроков')),
                  DropdownMenuItem(value: 10, child: Text('10 уроков')),
                ],
                onChanged: (v) => setState(() => limit = v ?? 0),
              ),
              const SizedBox(height: 14),
              const Text('Курсы, доступные ребёнку',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              for (final c in courses)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(asStr(c['title'])),
                  value: !hidden.contains(asStr(c['id'])),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      hidden.remove(asStr(c['id']));
                    } else {
                      hidden.add(asStr(c['id']));
                    }
                  }),
                ),
              if (isNew) ...[
                const SizedBox(height: 8),
                CheckRow(
                  value: consent,
                  onChanged: (v) => setState(() => consent = v),
                  text:
                      'Я законный представитель ребёнка и даю согласие на обработку его данных. Фамилию, адрес и телефон не указываю.',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => openDoc('consent-child.html'),
                    child: const Text('Прочитать согласие'),
                  ),
                ),
              ],
              MsgText(msg, err: msgErr, ok: !msgErr && msg.isNotEmpty),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52)),
                    onPressed: busy ? null : _save,
                    child: Text(busy ? 'Подождите…' : 'Сохранить'),
                  ),
                ),
                if (!isNew) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: _delete,
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFC0392B)),
                    child: const Text('Удалить'),
                  ),
                ],
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
