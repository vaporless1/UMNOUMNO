import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../art.dart';
import '../config.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import '../icons.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController name;
  late final TextEditingController uname;
  late final TextEditingController about;
  final TextEditingController promo = TextEditingController();
  final TextEditingController pin = TextEditingController();
  final TextEditingController pass = TextEditingController();
  bool weekly = true;
  String theme = 'brown';
  String unameMsg = '';
  bool unameOk = false;
  String msg = '';
  bool msgErr = false;
  String promoMsg = '';
  bool promoErr = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final me = app.me;
    name = TextEditingController(text: app.myName);
    uname = TextEditingController(
        text: asStr(me['username']).isEmpty ? '' : '@${asStr(me['username'])}');
    about = TextEditingController(text: asStr(me['about']));
    weekly = me['report_weekly'] != false;
    theme = asStr(me['theme']).isEmpty ? 'brown' : asStr(me['theme']);
  }

  @override
  void dispose() {
    timer?.cancel();
    name.dispose();
    uname.dispose();
    about.dispose();
    promo.dispose();
    pin.dispose();
    pass.dispose();
    super.dispose();
  }

  void _say(String m, {bool err = false}) {
    if (!mounted) return;
    setState(() {
      msg = m;
      msgErr = err;
    });
  }

  void _unameChanged(String raw) {
    timer?.cancel();
    final v = cleanUname(raw);
    final own = asStr(app.me['username']);
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
      _say('Загружаем фото…');
      final bytes = await x.readAsBytes();
      final path = '${app.user!.id}/avatar.jpg';
      await sb.storage.from('avatars').uploadBinary(path, bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'));
      final url =
          '${sb.storage.from('avatars').getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
      await sb.from('profiles').update({'avatar_url': url}).eq('id', app.user!.id);
      app.me['avatar_url'] = url;
      app.refresh();
      _say('Фото обновлено');
    } catch (e) {
      _say('Не удалось загрузить фото: ${errText(e)}', err: true);
    }
  }

  Future<void> _removePhoto() async {
    try {
      await sb.from('profiles').update({'avatar_url': null}).eq('id', app.user!.id);
      app.me['avatar_url'] = null;
      app.refresh();
      if (mounted) setState(() {});
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  Future<void> _saveProfile() async {
    final un = cleanUname(uname.text);
    if (un.isNotEmpty && !unameRe.hasMatch(un)) {
      _say('Юзернейм: 3–20 символов, латиница, цифры и _', err: true);
      return;
    }
    final row = <String, dynamic>{
      'full_name': name.text.trim(),
      'username': un.isEmpty ? null : un,
      'about': about.text.trim().isEmpty ? null : about.text.trim(),
      'theme': theme,
      'report_weekly': weekly,
    };
    try {
      await sb.from('profiles').update(row).eq('id', app.user!.id);
      app.me.addAll(row);
      app.refresh();
      _say('Сохранено!');
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  Future<void> _promo() async {
    final code = promo.text.trim();
    if (code.isEmpty) {
      setState(() {
        promoMsg = 'Введите промокод';
        promoErr = true;
      });
      return;
    }
    setState(() {
      promoMsg = 'Проверяем…';
      promoErr = false;
    });
    try {
      final r = await sb.rpc('redeem_promo', params: {'p_code': code});
      await app.reloadMe();
      if (!mounted) return;
      setState(() {
        promoMsg = r == null ? 'Промокод применён' : r.toString();
        promoErr = false;
        promo.clear();
      });
    } catch (e) {
      if (!mounted) return;
      final m = e.toString();
      final i = m.indexOf('message:');
      var t = errText(e);
      if (i >= 0) {
        final rest = m.substring(i + 8);
        final j = rest.indexOf(',');
        t = (j > 0 ? rest.substring(0, j) : rest).trim();
      }
      setState(() {
        promoMsg = t;
        promoErr = true;
      });
    }
  }

  Future<void> _setPin() async {
    final v = pin.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(v)) {
      _say('PIN — ровно 4 цифры', err: true);
      return;
    }
    try {
      await app.setPin(v);
      pin.clear();
      _say('PIN сохранён');
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  Future<void> _delPin() async {
    try {
      await app.setPin(null);
      _say('PIN удалён');
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  Future<void> _changePass() async {
    final p = pass.text;
    if (p.length < 8) {
      _say('Пароль — минимум 8 символов', err: true);
      return;
    }
    try {
      await sb.auth.updateUser(UserAttributes(password: p));
      pass.clear();
      _say('Пароль изменён.');
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  Future<void> _requestDelete() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent('Удаление аккаунта')}'
          '&body=${Uri.encodeComponent('Прошу удалить мой аккаунт и все связанные персональные данные, включая профили детей.\nE-mail аккаунта: ${app.user?.email}\nID: ${asStr(app.me['public_id'])}')}',
    );
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) toast(context, 'Напишите на $supportEmail', err: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль родителя'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListenableBuilder(
        listenable: app,
        builder: (context, _) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final me = app.me;
    final plan = asStr(me['plan']);
    final until = DateTime.tryParse(asStr(me['plan_until']));
    final live = plan.isNotEmpty && plan != 'none' && until != null && until.isAfter(DateTime.now());
    final planName = planNames[plan] ?? 'Нет подписки';
    final sub = live
        ? '$planName · до ${fd(me['plan_until'])}'
        : (plan.isEmpty || plan == 'none')
            ? planNames['none']!
            : '$planName · истекла ${fd(me['plan_until'])}';
    final opened = app.grants
        .where((g) {
          final e = DateTime.tryParse(asStr(g['expires_at']));
          return e == null || e.isAfter(DateTime.now());
        })
        .map((g) {
          final found = app.courses.where((x) => x['id'] == g['course_id']);
          return found.isEmpty ? asStr(g['course_id']) : asStr(found.first['title']);
        })
        .toList();
    final isAdmin = asBool(me['is_admin']) || me['role'] != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
      children: [
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Avatar(
                  url: asStr(me['avatar_url']),
                  name: app.myName,
                  size: 72),
              const SizedBox(width: 14),
              Wrap(spacing: 6, children: [
                OutlinedButton(
                    onPressed: _pickPhoto, child: const Text('Загрузить фото')),
                if (asStr(me['avatar_url']).isNotEmpty)
                  TextButton(onPressed: _removePhoto, child: const Text('убрать')),
              ]),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              maxLength: 60,
              decoration: const InputDecoration(labelText: 'Ваше имя'),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: uname,
              maxLength: 21,
              autocorrect: false,
              decoration: const InputDecoration(labelText: '@юзернейм'),
              onChanged: _unameChanged,
            ),
            MsgText(unameMsg, ok: unameOk, err: !unameOk && unameMsg.isNotEmpty),
            TextField(
              controller: about,
              maxLength: 300,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'О себе'),
            ),
            const SizedBox(height: 8),
            const Text('Цвет оформления',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, children: [
              for (final e in themes.entries)
                GestureDetector(
                  onTap: () {
                    setState(() => theme = e.key);
                    app.me['theme'] = e.key;
                    app.refresh();
                  },
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Color(e.value[0]),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme == e.key ? Colors.black87 : Colors.transparent,
                          width: 3),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 8),
            CheckRow(
              value: weekly,
              onChanged: (v) => setState(() => weekly = v),
              text: 'Присылать недельный отчёт на ${app.user?.email ?? ''}',
            ),
            MsgText(msg, err: msgErr, ok: !msgErr && msg.isNotEmpty),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _saveProfile,
              child: const Text('Сохранить'),
            ),
          ]),
        ),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('Ваш ID: ${asStr(me['public_id']).isEmpty ? '—' : asStr(me['public_id'])}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: asStr(me['public_id'])));
                  toast(context, 'ID скопирован');
                },
                child: const Text('скопировать'),
              ),
            ]),
            const Muted('Назовите ID в поддержке, чтобы мы быстро нашли ваш аккаунт.'),
            const Divider(height: 28),
            Text('Подписка: $sub', style: const TextStyle(fontWeight: FontWeight.w800)),
            if (opened.isNotEmpty) Muted('Открытые курсы: ${opened.join(', ')}'),
          ]),
        ),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const H2('Промокод'),
            const Muted('Есть промокод? Введите его, чтобы получить подписку или курс.'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: promo,
                  textCapitalization: TextCapitalization.characters,
                  autocorrect: false,
                  maxLength: 32,
                  decoration: const InputDecoration(
                      hintText: 'Например, SPRING2026', counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(onPressed: _promo, child: const Text('Применить')),
            ]),
            MsgText(promoMsg, err: promoErr, ok: !promoErr && promoMsg.isNotEmpty),
          ]),
        ),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const H2('Родительский контроль'),
            Text('PIN-код для выхода из режима ребёнка: ${app.hasPin ? 'установлен' : 'не задан'}'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: pin,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration:
                      const InputDecoration(hintText: '4 цифры', counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                  onPressed: _setPin,
                  child: Text(app.hasPin ? 'Сменить' : 'Установить')),
            ]),
            if (app.hasPin)
              TextButton(onPressed: _delPin, child: const Text('Убрать PIN')),
            const Muted('Лимит уроков в день и доступные курсы настраиваются в профиле каждого ребёнка.'),
          ]),
        ),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const H2('Смена пароля'),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(
                  hintText: 'Новый пароль (минимум 8 символов)'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(onPressed: _changePass, child: const Text('Изменить пароль')),
          ]),
        ),
        Box(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const H2('Документы и ваши данные'),
            const Muted(
                'Вы можете в любой момент удалить профиль ребёнка (на главном экране), отключить недельный отчёт или отозвать согласие и удалить аккаунт.'),
            const SizedBox(height: 6),
            const DocLinks(consent: true),
            const SizedBox(height: 8),
            OutlinedButton(
                onPressed: _requestDelete,
                child: const Text('Запросить удаление аккаунта и данных')),
          ]),
        ),
        if (isAdmin)
          Box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const H2('Администратор'),
              const Muted('Админ-панель работает на сайте — откроется в браузере.'),
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () => openUrl('$siteUrl/admin.html'),
                  child: const Text('Открыть админ-панель')),
            ]),
          ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: Colors.white),
          onPressed: () async {
            await app.signOut();
            if (context.mounted) {
              Navigator.of(context).popUntil((r) => r.isFirst);
            }
          },
          icon: const Ic(Si.out),
          label: const Text('Выйти из аккаунта'),
        ),
      ],
    );
  }
}
