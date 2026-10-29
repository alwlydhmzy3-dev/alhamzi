import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../sources/source.dart';

class ReaderScreen extends StatefulWidget {
  final Manga? manga;
  final List<Chapter> chapters;
  final int index;
  final String? localTitle;
  final List<PageRef>? localPages;
  const ReaderScreen({super.key, required Manga this.manga, required this.chapters, required this.index})
      : localTitle = null, localPages = null;
  const ReaderScreen.local({super.key, required String title, required List<PageRef> pages})
      : manga = null, chapters = const [], index = 0, localTitle = title, localPages = pages;
  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late int idx = widget.index;
  List<PageRef>? pages;
  String? error;
  bool ui = true;
  int cur = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _load();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { pages = null; error = null; cur = 0; });
    if (widget.localPages != null) { setState(() => pages = widget.localPages); return; }
    final c = widget.chapters[idx];
    try {
      final p = await sourceById(widget.manga!.source).pages(c);
      if (!mounted) return;
      context.read<AppState>().markRead(widget.manga!, c);
      setState(() => pages = p);
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر تحميل صفحات الفصل');
    }
  }

  Widget _img(PageRef p, {BoxFit fit = BoxFit.fitWidth}) {
    if (p.bytes != null) return Image.memory(p.bytes!, fit: fit, width: double.infinity);
    return Image.network(
      p.url!, fit: fit, width: double.infinity,
      loadingBuilder: (c, w, prog) => prog == null ? w : const SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
      errorBuilder: (_, __, ___) => const SizedBox(height: 200, child: Center(child: Icon(Icons.broken_image))),
    );
  }

  bool get _hasNext => widget.localPages == null && idx < widget.chapters.length - 1;

  void _next() { if (_hasNext) { idx++; _load(); } }
  void _prev() { if (widget.localPages == null && idx > 0) { idx--; _load(); } }

  @override
  Widget build(BuildContext context) {
    final mode = context.watch<AppState>().readerMode;
    final title = widget.localTitle ?? widget.chapters[idx].title;
    Widget body;
    if (error != null) {
      body = Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: _load, child: const Text('إعادة المحاولة'))]));
    } else if (pages == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (mode == 'webtoon') {
      body = ListView.builder(
        cacheExtent: 2500,
        itemCount: pages!.length + 1,
        itemBuilder: (_, i) => i == pages!.length ? _endBar() : _img(pages![i]),
      );
    } else {
      body = PageView.builder(
        reverse: mode == 'rtl',
        onPageChanged: (i) => setState(() => cur = i),
        itemCount: pages!.length + 1,
        itemBuilder: (_, i) => i == pages!.length
            ? _endBar()
            : InteractiveViewer(child: Center(child: _img(pages![i], fit: BoxFit.contain))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onDoubleTap: () => setState(() => ui = !ui),
        child: Stack(children: [
          Positioned.fill(child: body),
          if (ui)
            Positioned(
              top: 0, left: 0, right: 0,
              child: AppBar(
                backgroundColor: Colors.black.withOpacity(0.65),
                title: Text(title, style: const TextStyle(fontSize: 15)),
                actions: [
                  if (widget.localPages == null) IconButton(onPressed: idx > 0 ? _prev : null, icon: const Icon(Icons.skip_next)),
                  if (widget.localPages == null) IconButton(onPressed: _hasNext ? _next : null, icon: const Icon(Icons.skip_previous)),
                ],
              ),
            ),
          if (ui && pages != null && mode != 'webtoon')
            Positioned(bottom: 12, left: 0, right: 0, child: Center(child: Chip(label: Text('${cur + 1} / ${pages!.length}')))),
        ]),
      ),
    );
  }

  Widget _endBar() => SizedBox(
        height: 220,
        child: Center(
          child: _hasNext
              ? FilledButton.icon(onPressed: _next, icon: const Icon(Icons.navigate_next), label: const Text('الفصل التالي'))
              : const Text('نهاية المتاح', style: TextStyle(color: Colors.white70)),
        ),
      );
}
