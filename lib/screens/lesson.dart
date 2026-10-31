import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../art.dart';
import '../kidui.dart';
import '../config.dart';
import '../quiz.dart';
import '../state.dart';
import '../util.dart';
import '../widgets.dart';
import '../icons.dart';
import '../theme.dart';

class LessonScreen extends StatefulWidget {
  final String lessonId;
  const LessonScreen({super.key, required this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  Map<String, dynamic>? lesson;
  Map<String, dynamic>? course;
  List<Map<String, dynamic>>? tasks;
  String? loadErr;
  bool quizOn = false;
  int quizKey = 0;
  bool drawing = false;
  bool marking = false;
  bool markedDone = false;
  int resumeSec = 0;

  @override
  void initState() {
    super.initState();
    lesson = app.lessonById(widget.lessonId);
    course = lesson == null ? null : app.courseOf(lesson!);
    if (lesson == null) return;
    if (app.limitReached && !app.isDone(widget.lessonId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }
    final pv = app.views.where((v) => v['lesson_id'] == widget.lessonId);
    resumeSec = pv.isEmpty ? 0 : asInt(pv.first['position_sec']);
    app.touchLesson(widget.lessonId, resumeSec);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final d = await sb
          .from('tasks')
          .select()
          .eq('lesson_id', widget.lessonId)
          .order('sort');
      if (!mounted) return;
      setState(() => tasks = rows(d));
    } catch (e) {
      if (!mounted) return;
      setState(() => loadErr = errText(e));
    }
  }

  void _setDrawing(bool v) {
    if (drawing == v) return;
    drawing = v;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      if (mounted) setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Map<String, dynamic>? get nextLesson {
    final c = course;
    if (c == null) return null;
    final ls = app.ofCourse(asStr(c['id']));
    final i = ls.indexWhere((l) => l['id'] == widget.lessonId);
    if (i < 0 || i + 1 >= ls.length) return null;
    return ls[i + 1];
  }

  Widget _actions(BuildContext context, int stars) {
    final nx = nextLesson;
    final hasTasks = (tasks ?? []).isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (nx != null && !app.limitReached)
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => LessonScreen(lessonId: asStr(nx['id']))),
          ),
          child: const Text('Следующий урок', style: TextStyle(fontSize: 17)),
        ),
      const SizedBox(height: 10),
      OutlinedButton(
        style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Colors.white),
        onPressed: () {
          if (hasTasks) {
            setState(() {
              quizOn = true;
              markedDone = false;
              quizKey++;
            });
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Text(hasTasks ? 'Пройти ещё раз' : 'К курсу'),
      ),
      if (hasTasks)
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('К курсу'),
        ),
    ]);
  }

  Future<List<Map<String, dynamic>>> _finish(int score, int total) =>
      app.saveProgress(widget.lessonId, score, total);

  Future<void> _markWatched() async {
    setState(() => marking = true);
    try {
      await app.saveProgress(widget.lessonId, null, null);
      if (!mounted) return;
      setState(() {
        markedDone = true;
        marking = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => marking = false);
      toast(context, errText(e), err: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = lesson;
    if (l == null) {
      return Scaffold(
        appBar: buildBar(context, title: 'Урок'),
        body: const Center(child: Text('Урок не найден')),
      );
    }
    final src = videoSrc(asStr(l['video_url']));
    final T = tasks;
    return Scaffold(
      appBar: buildBar(context,
          title: course == null ? 'Урок' : asStr(course!['title'])),
      body: Backdrop(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: drawing ? const NeverScrollableScrollPhysics() : null,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
            child: app.kidMode
                ? KidPanel(margin: const EdgeInsets.only(top: 8), child: _inner(l, src, T))
                : Box(child: _inner(l, src, T)),
          ),
        ),
      ),
    );
  }

  Widget _inner(Map<String, dynamic> l, VideoSrc? src, List<Map<String, dynamic>>? T) {
    return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(asStr(l['title']),
                        style: hd(21)),
                    if (asStr(l['description']).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Muted(asStr(l['description']), size: 14),
                      ),
                    const SizedBox(height: 14),
                    if (!quizOn) ...[
                      _videoBlock(src, asStr(l['video_url'])),
                      const SizedBox(height: 18),
                      _startBlock(T),
                    ] else if (T != null)
                      QuizRunner(
                        key: ValueKey('quiz$quizKey'),
                        tasks: T,
                        onFinish: _finish,
                        actions: _actions,
                        onDrawing: _setDrawing,
                      ),
                  ],
                );
  }

  Widget _videoBlock(VideoSrc? src, String rawUrl) {
    if (src == null) {
      return Container(
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFEE),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('Видео скоро появится'),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: app.kidMode
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white, width: 6),
                boxShadow: kidShadow(8, 0.1),
              )
            : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(app.kidMode ? 22 : 18),
          child: src.kind == 'file'
              ? FileVideo(
                  key: ValueKey(src.url),
                  url: src.url,
                  resumeSec: resumeSec,
                  onPosition: (s) => app.touchLesson(widget.lessonId, s),
                )
              : WebVideo(key: ValueKey(src.url), url: src.url),
        ),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () => openUrl(rawUrl),
          icon: const Ic(Si.ext, size: 16),
          label: const Text('Открыть в браузере'),
        ),
      ),
    ]);
  }

  Widget _startBlock(List<Map<String, dynamic>>? T) {
    if (loadErr != null) return MsgText(loadErr!, err: true);
    if (T == null) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(12),
        child: CircularProgressIndicator(),
      ));
    }
    if (markedDone) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Урок пройден!',
            textAlign: TextAlign.center,
            style: hd(22)),
        const SizedBox(height: 12),
        _actions(context, 3),
      ]);
    }
    if (T.isEmpty) {
      return FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
        onPressed: marking ? null : _markWatched,
        child: const Text('Я посмотрел урок', style: TextStyle(fontSize: 18)),
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: app.kidMode ? kKidGreen : null),
      onPressed: () => setState(() => quizOn = true),
      child: Text('Выполнить задания (${T.length})',
          style: const TextStyle(fontSize: 18)),
    );
  }
}

// =====================================================================
//  Видео из YouTube / RuTube / Vimeo (встроенный плеер)
// =====================================================================
class WebVideo extends StatefulWidget {
  final String url;
  const WebVideo({super.key, required this.url});

  @override
  State<WebVideo> createState() => _WebVideoState();
}

class _WebVideoState extends State<WebVideo> {
  late final WebViewController ctrl;

  @override
  void initState() {
    super.initState();
    final html = '<html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head>'
        '<body style="margin:0;background:#000"><iframe src="${widget.url}" '
        'style="position:absolute;top:0;left:0;width:100%;height:100%;border:0" '
        'allow="autoplay; fullscreen; encrypted-media; picture-in-picture" '
        'allowfullscreen></iframe></body></html>';
    ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (req) {
          if (!req.isMainFrame) return NavigationDecision.navigate;
          if (req.url.startsWith(siteUrl) || req.url.startsWith('about:')) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ))
      ..loadHtmlString(html, baseUrl: siteUrl);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: WebViewWidget(controller: ctrl),
    );
  }
}

// =====================================================================
//  Видео-файл (mp4/webm) с запоминанием места
// =====================================================================
class FileVideo extends StatefulWidget {
  final String url;
  final int resumeSec;
  final void Function(int sec) onPosition;
  const FileVideo(
      {super.key,
      required this.url,
      required this.resumeSec,
      required this.onPosition});

  @override
  State<FileVideo> createState() => _FileVideoState();
}

class _FileVideoState extends State<FileVideo> {
  late final VideoPlayerController c;
  Timer? timer;
  bool ready = false;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    c = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    c.addListener(() {
      if (mounted) setState(() {});
    });
    c.initialize().then((_) {
      if (!mounted) return;
      final dur = c.value.duration.inSeconds;
      if (widget.resumeSec > 5 && widget.resumeSec < dur - 8) {
        c.seekTo(Duration(seconds: widget.resumeSec));
      }
      setState(() => ready = true);
    }).catchError((Object e) {
      if (mounted) setState(() => failed = true);
    });
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (ready && c.value.isPlaying) {
        widget.onPosition(c.value.position.inSeconds);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    if (ready) widget.onPosition(c.value.position.inSeconds);
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Container(
        color: Colors.black,
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Видео не загрузилось',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text(
              'Файл недоступен или не воспроизводится. Проверьте интернет или откройте файл в браузере.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70)),
        ]),
      );
    }
    if (!ready) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    final v = c.value;
    return Column(children: [
      AspectRatio(
        aspectRatio: v.aspectRatio == 0 ? 16 / 9 : v.aspectRatio,
        child: Stack(alignment: Alignment.center, children: [
          GestureDetector(
            onTap: () {
              if (v.isPlaying) {
                c.pause();
                widget.onPosition(v.position.inSeconds);
              } else {
                c.play();
              }
            },
            child: VideoPlayer(c),
          ),
          if (!v.isPlaying)
            IgnorePointer(
              child: Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Ic(Si.play,
                    color: Colors.white, size: 46),
              ),
            ),
        ]),
      ),
      Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        child: Row(children: [
          Text(fmtT(v.position.inSeconds),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: VideoProgressIndicator(c,
                allowScrubbing: true,
                padding: const EdgeInsets.symmetric(vertical: 8)),
          ),
          const SizedBox(width: 8),
          Text(fmtT(v.duration.inSeconds),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ]),
      ),
    ]);
  }
}
