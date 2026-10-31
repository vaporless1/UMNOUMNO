import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'intro.dart';
import 'scene.dart';
import 'screens/auth.dart';
import 'screens/home.dart';
import 'screens/kid.dart';
import 'state.dart';
import 'theme.dart';
import 'util.dart';
import 'widgets.dart';
import 'icons.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
bool _supabaseReady = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  shopOpener = (c) {
    if (ModalRoute.of(c)?.settings.name == 'shop') return;
    Navigator.of(c).push(MaterialPageRoute(
        settings: const RouteSettings(name: 'shop'),
        builder: (_) => const ShopScreen()));
  };
  runApp(const UmnoApp());
}

class UmnoApp extends StatefulWidget {
  const UmnoApp({super.key});

  @override
  State<UmnoApp> createState() => _UmnoAppState();
}

class _UmnoAppState extends State<UmnoApp> {
  bool booting = true;
  bool _introDone = false;
  String? bootError;

  @override
  void initState() {
    super.initState();
    app.addListener(_onApp);
    _boot();
  }

  @override
  void dispose() {
    app.removeListener(_onApp);
    super.dispose();
  }

  // Если сессия закончилась — возвращаемся на экран входа.
  void _onApp() {
    if (app.user == null) {
      navKey.currentState?.popUntil((r) => r.isFirst);
    }
  }

  Future<void> _boot() async {
    setState(() {
      booting = true;
      bootError = null;
    });
    try {
      if (!_supabaseReady) {
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        _supabaseReady = true;
      }
      await app.init();
    } catch (e) {
      bootError = errText(e);
    }
    if (mounted) setState(() => booting = false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        final ready = !booting &&
            (bootError != null ||
                (app.ready &&
                    (app.user == null ||
                        app.loaded ||
                        app.loadError != null ||
                        app.blocked)));
        return MaterialApp(
          title: 'УМНО',
          debugShowCheckedModeBanner: false,
          navigatorKey: navKey,
          builder: (context, child) => Stack(
            children: [
              child ?? const SizedBox.shrink(),
              if (!_introDone)
                Positioned.fill(
                  child: IntroSplash(
                    ready: ready,
                    onDone: () => setState(() => _introDone = true),
                  ),
                ),
            ],
          ),
          theme: themeFor(themeColor(asStr(app.me['theme'])), kid: app.kidMode),
          home: booting
              ? const Splash()
              : bootError != null
                  ? ErrorScreen(message: bootError!, onRetry: _boot)
                  : const Gate(),
        );
      },
    );
  }
}

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const MascotAnim(height: 170),
          const SizedBox(height: 10),
          Text.rich(
            const TextSpan(children: [
              TextSpan(text: 'УМ'),
              TextSpan(text: 'НО', style: TextStyle(color: Color(0xFFB07F5E))),
            ]),
            style: hd(40),
          ),
          const SizedBox(height: 16),
          const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3)),
        ]),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  final bool canLogout;
  const ErrorScreen({
    super.key,
    required this.message,
    required this.onRetry,
    this.canLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Ic(Si.cloudoff, size: 52, color: Colors.black45),
            const SizedBox(height: 14),
            Text('Не удалось загрузить данные',
                textAlign: TextAlign.center,
                style: hd(20)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 18),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
            if (canLogout)
              TextButton(
                  onPressed: () => app.signOut(), child: const Text('Выйти из аккаунта')),
          ]),
        ),
      ),
    );
  }
}

/// Выбирает, какой экран показать: вход, ошибка, родитель или ребёнок.
class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: app,
      builder: (context, _) {
        if (!app.ready) return const Splash();
        if (app.user == null) return const AuthScreen();
        if (app.blocked) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Ic(Si.block, size: 52, color: Colors.black45),
                  const SizedBox(height: 14),
                  Text('Аккаунт заблокирован',
                      style: hd(22)),
                  const SizedBox(height: 8),
                  Text(
                      'Напишите в поддержку ($supportEmail) и назовите ваш ID: ${asStr(app.me['public_id'])}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 18),
                  OutlinedButton(
                      onPressed: () => app.signOut(),
                      child: const Text('Выйти из аккаунта')),
                ]),
              ),
            ),
          );
        }
        if (!app.loaded) {
          if (app.loadError != null) {
            return ErrorScreen(
              message: app.loadError!,
              onRetry: () => app.retry(),
              canLogout: true,
            );
          }
          return const Splash();
        }
        return app.kidMode ? const KidHome() : const ParentHome();
      },
    );
  }
}
