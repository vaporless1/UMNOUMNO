import 'dart:async';

import 'package:flutter/material.dart';

import '../config.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import '../icons.dart';
import '../theme.dart';

/// Вход и регистрация родителя.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool reg = false;
  bool busy = false;
  String msg = '';
  bool msgErr = false;

  final TextEditingController lEmail = TextEditingController();
  final TextEditingController lPass = TextEditingController();
  final TextEditingController rName = TextEditingController();
  final TextEditingController rUser = TextEditingController();
  final TextEditingController rEmail = TextEditingController();
  final TextEditingController rPass = TextEditingController();
  bool cTerms = false;
  bool cPd = false;
  bool cAds = false;
  bool showPass = false;
  String unameMsg = '';
  bool unameOk = false;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    for (final c in [lEmail, lPass, rName, rUser, rEmail, rPass]) {
      c.dispose();
    }
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
    if (v.isEmpty) {
      setState(() => unameMsg = '');
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

  Future<void> _login() async {
    final email = lEmail.text.trim();
    if (email.isEmpty || lPass.text.isEmpty) {
      _say('Введите e-mail и пароль.', err: true);
      return;
    }
    setState(() => busy = true);
    try {
      await sb.auth.signInWithPassword(email: email, password: lPass.text);
      // дальше всё сделает слушатель состояния авторизации
    } catch (e) {
      _say(errText(e), err: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _register() async {
    final un = cleanUname(rUser.text);
    final email = rEmail.text.trim();
    if (rName.text.trim().isEmpty || email.isEmpty) {
      _say('Заполните имя и e-mail.', err: true);
      return;
    }
    if (rPass.text.length < 8) {
      _say('Пароль — минимум 8 символов.', err: true);
      return;
    }
    if (un.isNotEmpty && !unameRe.hasMatch(un)) {
      _say('Юзернейм: 3–20 символов, латиница, цифры и _', err: true);
      return;
    }
    if (!cTerms) {
      _say('Подтвердите, что вам есть 18 лет, и примите Пользовательское соглашение.',
          err: true);
      return;
    }
    if (!cPd) {
      _say('Для регистрации нужно согласие на обработку персональных данных.',
          err: true);
      return;
    }
    setState(() => busy = true);
    final at = DateTime.now().toUtc().toIso8601String();
    final rec = {'v': legalVersion, 'at': at};
    try {
      final r = await sb.auth.signUp(
        email: email,
        password: rPass.text,
        emailRedirectTo: '$siteUrl/cabinet.html',
        data: {
          'full_name': rName.text.trim(),
          'username': un.isEmpty ? null : un,
          'consent_terms': rec,
          'consent_pd': rec,
          'consent_ads': cAds ? rec : null,
        },
      );
      if (r.session == null && mounted) {
        setState(() {
          reg = false;
          lEmail.text = email;
        });
        _say('Готово! Мы отправили письмо — подтвердите почту и войдите.');
      }
    } catch (e) {
      _say(errText(e), err: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _forgot() async {
    final email = lEmail.text.trim();
    if (email.isEmpty) {
      _say('Введите e-mail выше, и мы пришлём ссылку для смены пароля.', err: true);
      return;
    }
    try {
      await sb.auth.resetPasswordForEmail(email, redirectTo: '$siteUrl/cabinet.html');
      _say('Если такой e-mail есть, мы отправили на него ссылку. Пароль меняется на сайте, после этого войдите здесь.');
    } catch (e) {
      _say(errText(e), err: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: primary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
          children: [
            Text.rich(
              TextSpan(children: [
                TextSpan(text: 'УМ'),
                TextSpan(text: 'НО', style: TextStyle(color: Colors.black87)),
              ]),
              style: hd(30, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text('Личный кабинет родителя',
                style: hd(22, color: Colors.white)),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Вход')),
                    ButtonSegment(value: true, label: Text('Регистрация')),
                  ],
                  selected: {reg},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() {
                    reg = s.first;
                    msg = '';
                  }),
                ),
                const SizedBox(height: 16),
                if (!reg) ..._loginForm() else ..._regForm(),
                MsgText(msg, err: msgErr, ok: !msgErr && msg.isNotEmpty),
              ]),
            ),
            const SizedBox(height: 12),
            const Center(child: DocLinks(consent: true)),
            const Center(
                child: Text('0+', style: TextStyle(color: Colors.white70))),
          ],
        ),
      ),
    );
  }

  List<Widget> _loginForm() => [
        Text('С возвращением!',
            style: hd(22)),
        const Muted('Войдите, чтобы продолжить обучение.', size: 14),
        const SizedBox(height: 14),
        TextField(
          controller: lEmail,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          decoration: const InputDecoration(hintText: 'E-mail'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: lPass,
          obscureText: !showPass,
          autocorrect: false,
          enableSuggestions: false,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _login(),
          decoration: InputDecoration(
            hintText: 'Пароль',
            suffixIcon: IconButton(
              icon: Ic(showPass ? Si.eyeoff : Si.eye),
              onPressed: () => setState(() => showPass = !showPass),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: _forgot, child: const Text('Забыли пароль?')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: busy ? null : _login,
          child: Text(busy ? 'Подождите…' : 'Войти', style: const TextStyle(fontSize: 16)),
        ),
      ];

  List<Widget> _regForm() => [
        Text('Создайте аккаунт',
            style: hd(22)),
        const Muted('Это займёт меньше минуты.', size: 14),
        const SizedBox(height: 14),
        TextField(
          controller: rName,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Ваше имя'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: rUser,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: _unameChanged,
          decoration:
              const InputDecoration(hintText: '@юзернейм (необязательно)'),
        ),
        MsgText(unameMsg, ok: unameOk, err: !unameOk && unameMsg.isNotEmpty),
        TextField(
          controller: rEmail,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(hintText: 'E-mail'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: rPass,
          obscureText: !showPass,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'Пароль (минимум 8 символов)',
            suffixIcon: IconButton(
              icon: Ic(showPass ? Si.eyeoff : Si.eye),
              onPressed: () => setState(() => showPass = !showPass),
            ),
          ),
        ),
        const SizedBox(height: 8),
        CheckRow(
          value: cTerms,
          onChanged: (v) => setState(() => cTerms = v),
          text:
              'Мне исполнилось 18 лет, я принимаю Пользовательское соглашение и ознакомлен(а) с Политикой конфиденциальности',
        ),
        CheckRow(
          value: cPd,
          onChanged: (v) => setState(() => cPd = v),
          text: 'Даю согласие на обработку моих персональных данных',
        ),
        CheckRow(
          value: cAds,
          onChanged: (v) => setState(() => cAds = v),
          text: 'Хочу получать новости и акции (необязательно)',
        ),
        const SizedBox(height: 8),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          onPressed: busy ? null : _register,
          child: Text(busy ? 'Подождите…' : 'Зарегистрироваться',
              style: const TextStyle(fontSize: 16)),
        ),
      ];
}
