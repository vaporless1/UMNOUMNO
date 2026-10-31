import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'util.dart';

SupabaseClient get sb => Supabase.instance.client;

/// SHA-256 от 'umno:' + PIN — тот же формат, что на сайте.
String pinHash(String pin) =>
    sha256.convert(utf8.encode('umno:$pin')).toString();

class LessonRef {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> course;
  final Map<String, dynamic> view;
  final Map<String, dynamic>? prog;
  const LessonRef(this.lesson, this.course, this.view, this.prog);
}

class ContinueTarget {
  final Map<String, dynamic> lesson;
  final Map<String, dynamic> course;
  final int pos;
  final String kind; // 'resume' | 'next'
  const ContinueTarget(this.lesson, this.course, this.pos, this.kind);
}

class AppState extends ChangeNotifier {
  SharedPreferences? prefs;

  User? user;
  Map<String, dynamic> me = {};
  List<Map<String, dynamic>> kids = [];
  List<Map<String, dynamic>> courses = [];
  List<Map<String, dynamic>> lessons = [];
  List<Map<String, dynamic>> badgesCat = [];
  List<Map<String, dynamic>> shopItems = [];
  List<Map<String, dynamic>> grants = [];
  List<Map<String, dynamic>> views = [];
  Map<String, Map<String, dynamic>> prog = {};
  Map<String, dynamic> stats = {};
  Map<String, String> earned = {};
  Set<String> owned = {};
  String? active;

  bool ready = false;
  bool loaded = false;
  bool blocked = false;
  bool kidMode = false;
  bool entering = false;
  bool _listening = false;
  String? loadError;
  String shopTab = 'bg';

  // ---------- запуск ----------
  Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    if (!_listening) {
      _listening = true;
      sb.auth.onAuthStateChange.listen((data) {
        _enter(data.session);
      });
    }
    await _enter(sb.auth.currentSession);
    ready = true;
    notifyListeners();
  }

  void _reset() {
    user = null;
    me = {};
    kids = [];
    courses = [];
    lessons = [];
    badgesCat = [];
    shopItems = [];
    grants = [];
    views = [];
    prog = {};
    stats = {};
    earned = {};
    owned = {};
    active = null;
    loaded = false;
    blocked = false;
    kidMode = false;
    loadError = null;
  }

  Future<void> _enter(Session? s) async {
    if (s == null) {
      _reset();
      notifyListeners();
      return;
    }
    if (entering) return;
    if (user != null && user!.id == s.user.id && loaded) {
      user = s.user;
      return;
    }
    entering = true;
    loadError = null;
    notifyListeners();
    try {
      user = s.user;
      await loadMe();
      if (asBool(me['blocked'])) {
        blocked = true;
        loaded = true;
        return;
      }
      blocked = false;
      await Future.wait<void>([loadCatalog(), loadKids()]);
      final saved = prefs?.getString('umno_kid_mode');
      kidMode = saved != null && kids.any((k) => k['id'] == saved);
      if (kidMode) active = saved;
      await loadChild();
      loaded = true;
    } catch (e) {
      loaded = false;
      loadError = errText(e);
    } finally {
      entering = false;
      notifyListeners();
    }
  }

  Future<void> retry() async {
    final s = sb.auth.currentSession;
    if (s == null) return;
    loaded = false;
    await _enter(s);
  }

  Future<void> signOut() async {
    await prefs?.remove('umno_kid_mode');
    await sb.auth.signOut();
  }

  // ---------- загрузка данных ----------
  String get myName {
    final n = asStr(me['full_name']);
    if (n.isNotEmpty) return n;
    final meta = asStr(user?.userMetadata?['full_name']);
    if (meta.isNotEmpty) return meta;
    final mail = asStr(user?.email);
    return mail.contains('@') ? mail.split('@').first : 'Родитель';
  }

  Future<void> loadMe() async {
    final data =
        await sb.from('profiles').select().eq('id', user!.id).maybeSingle();
    me = data == null ? {} : Map<String, dynamic>.from(data);
    if (me['role'] != null) {
      try {
        final r = await sb.rpc('my_perms');
        final perms = asList(asMap(r)['perms']);
        me['tester'] = perms.contains('test_access');
      } catch (_) {}
    }
    final g = await sb.from('course_access').select('course_id,expires_at');
    grants = rows(g);
  }

  Future<void> loadCatalog() async {
    final c = await sb.from('courses').select().order('sort');
    final l = await sb.from('lessons').select().order('sort');
    final b = await sb.from('badges').select().order('sort');
    final sh = await sb.from('shop_items').select().order('sort');
    courses = rows(c);
    lessons = rows(l);
    badgesCat = rows(b);
    shopItems = rows(sh);
  }

  Future<void> loadKids() async {
    final d = await sb.from('children').select().order('created_at');
    kids = rows(d);
    if (!kids.any((k) => k['id'] == active)) {
      final saved = prefs?.getString('umno_kid');
      if (saved != null && kids.any((k) => k['id'] == saved)) {
        active = saved;
      } else {
        active = kids.isEmpty ? null : asStr(kids.first['id']);
      }
    }
  }

  Future<void> loadChild() async {
    prog = {};
    stats = {};
    earned = {};
    owned = {};
    views = [];
    if (active == null) return;
    final p = await sb.from('progress').select().eq('child_id', active!);
    for (final x in rows(p)) {
      prog[asStr(x['lesson_id'])] = x;
    }
    try {
      stats = asMap(await sb.rpc('child_stats', params: {'p_child': active}));
    } catch (_) {
      stats = {};
    }
    final b = await sb.from('child_badges').select().eq('child_id', active!);
    for (final x in rows(b)) {
      earned[asStr(x['badge_id'])] = asStr(x['earned_at']);
    }
    final o = await sb.from('child_items').select('item_id').eq('child_id', active!);
    for (final x in rows(o)) {
      owned.add(asStr(x['item_id']));
    }
    final v = await sb
        .from('lesson_views')
        .select()
        .eq('child_id', active!)
        .order('last_at', ascending: false)
        .limit(30);
    views = rows(v);
  }

  Future<void> reloadAll() async {
    await loadKids();
    await loadChild();
    notifyListeners();
  }

  Future<void> reloadMe() async {
    await loadMe();
    notifyListeners();
  }

  // ---------- выбор ребёнка ----------
  Map<String, dynamic>? get kid {
    for (final k in kids) {
      if (k['id'] == active) return k;
    }
    return null;
  }

  Future<void> selectKid(String id) async {
    active = id;
    await prefs?.setString('umno_kid', id);
    await loadChild();
    notifyListeners();
  }

  // ---------- доступ и каталог ----------
  bool canAccess(String courseId) {
    if (asBool(me['is_admin']) || asBool(me['tester'])) return true;
    final now = DateTime.now();
    final plan = asStr(me['plan']);
    final until = DateTime.tryParse(asStr(me['plan_until']));
    if (['trial', 'family', 'year'].contains(plan) &&
        until != null &&
        until.isAfter(now)) {
      return true;
    }
    for (final g in grants) {
      if (asStr(g['course_id']) != courseId) continue;
      final e = DateTime.tryParse(asStr(g['expires_at']));
      if (e == null || e.isAfter(now)) return true;
    }
    return false;
  }

  List<Map<String, dynamic>> ofCourse(String id) =>
      lessons.where((l) => asStr(l['course_id']) == id).toList();

  List<Map<String, dynamic>> get visibleCourses {
    if (!kidMode) return courses;
    final hidden = asList(kid?['hidden_courses']).map((e) => asStr(e)).toList();
    return courses.where((c) => !hidden.contains(asStr(c['id']))).toList();
  }

  Map<String, dynamic>? courseOf(Map<String, dynamic> lesson) {
    for (final c in courses) {
      if (c['id'] == lesson['course_id']) return c;
    }
    return null;
  }

  Map<String, dynamic>? lessonById(String id) {
    for (final l in lessons) {
      if (l['id'] == id) return l;
    }
    return null;
  }

  bool isDone(String lessonId) => asBool(prog[lessonId]?['completed']);

  bool get limitReached {
    final k = kid;
    if (!kidMode || k == null) return false;
    final lim = asInt(k['daily_limit']);
    return lim > 0 && asInt(stats['today']) >= lim;
  }

  bool openable(Map<String, dynamic> l) {
    final c = courseOf(l);
    if (c == null || !canAccess(asStr(c['id']))) return false;
    if (kidMode) return visibleCourses.any((x) => x['id'] == c['id']);
    return true;
  }

  List<LessonRef> recentLessons(int n) {
    final out = <LessonRef>[];
    for (final v in views) {
      final l = lessonById(asStr(v['lesson_id']));
      if (l != null && openable(l)) {
        out.add(LessonRef(l, courseOf(l)!, v, prog[asStr(l['id'])]));
      }
      if (out.length >= n) break;
    }
    return out;
  }

  ContinueTarget? continueTarget() {
    for (final v in views) {
      final l = lessonById(asStr(v['lesson_id']));
      if (l != null && !isDone(asStr(l['id'])) && openable(l)) {
        return ContinueTarget(
            l, courseOf(l)!, asInt(v['position_sec']), 'resume');
      }
    }
    final order = <String>[];
    if (views.isNotEmpty) {
      final last = lessonById(asStr(views.first['lesson_id']));
      if (last != null) order.add(asStr(last['course_id']));
    }
    order.addAll(visibleCourses.map((c) => asStr(c['id'])));
    for (final cid in order) {
      Map<String, dynamic>? c;
      for (final x in courses) {
        if (x['id'] == cid) c = x;
      }
      if (c == null || !canAccess(cid)) continue;
      if (kidMode && !visibleCourses.any((x) => x['id'] == cid)) continue;
      for (final l in ofCourse(cid)) {
        if (!isDone(asStr(l['id']))) {
          return ContinueTarget(l, c, 0, 'next');
        }
      }
    }
    return null;
  }

  // ---------- оформление ребёнка ----------
  Map<String, dynamic>? equippedItem(String kind) {
    final eq = asMap(kid?['equipped']);
    final id = eq[kind];
    if (id == null) return null;
    for (final i in shopItems) {
      if (i['id'] == id) return i;
    }
    return null;
  }

  String equippedArt(String kind) {
    final it = equippedItem(kind);
    final a = asStr(it?['art']);
    if (a.isNotEmpty) return a;
    return kind == 'bg' ? 'meadow' : '';
  }

  int get balance {
    if (stats['balance'] != null) return asInt(stats['balance']);
    return asInt(stats['stars']);
  }

  // ---------- голос ----------
  bool get voicePref {
    final v = prefs?.getString('umno_voice');
    if (v == null) return kidMode;
    return v == '1';
  }

  Future<void> setVoicePref(bool on) async {
    await prefs?.setString('umno_voice', on ? '1' : '0');
    notifyListeners();
  }

  // ---------- просмотры и прогресс ----------
  Future<void> touchLesson(String id, int pos) async {
    if (active == null) return;
    final row = {
      'child_id': active,
      'lesson_id': id,
      'last_at': DateTime.now().toUtc().toIso8601String(),
      'position_sec': pos < 0 ? 0 : pos,
    };
    views.removeWhere((v) => v['lesson_id'] == id);
    views.insert(0, Map<String, dynamic>.from(row));
    try {
      await sb.from('lesson_views').upsert(row, onConflict: 'child_id,lesson_id');
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> saveProgress(
      String lessonId, int? score, int? total) async {
    await sb.from('progress').upsert({
      'child_id': active,
      'lesson_id': lessonId,
      'completed': true,
      'score': score,
      'total': total,
    }, onConflict: 'child_id,lesson_id');
    var badges = <Map<String, dynamic>>[];
    try {
      final r = await sb.rpc('refresh_badges', params: {'p_child': active});
      badges = rows(r);
    } catch (_) {}
    await loadChild();
    notifyListeners();
    return badges;
  }

  // ---------- режим ребёнка ----------
  Future<void> enterKidMode() async {
    kidMode = true;
    await prefs?.setString('umno_kid_mode', active ?? '');
    await loadChild();
    notifyListeners();
  }

  Future<void> leaveKidMode() async {
    kidMode = false;
    await prefs?.remove('umno_kid_mode');
    notifyListeners();
  }

  Future<void> setPin(String? pin) async {
    final h = pin == null ? null : pinHash(pin);
    await sb.from('profiles').update({'pin_hash': h}).eq('id', user!.id);
    me['pin_hash'] = h;
    notifyListeners();
  }

  bool checkPin(String pin) => pinHash(pin) == asStr(me['pin_hash']);
  bool get hasPin => asStr(me['pin_hash']).isNotEmpty;

  // ---------- магазин ----------
  Future<void> buy(String itemId) async {
    await sb.rpc('buy_item', params: {'p_child': active, 'p_item': itemId});
    await reloadAll();
  }

  Future<void> equip(String kind, String itemId) async {
    await sb.rpc('equip_item',
        params: {'p_child': active, 'p_kind': kind, 'p_item': itemId});
    await reloadAll();
  }

  void setShopTab(String t) {
    shopTab = t;
    notifyListeners();
  }

  void refresh() => notifyListeners();
}

final AppState app = AppState();
