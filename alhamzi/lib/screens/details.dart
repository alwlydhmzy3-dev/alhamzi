import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../sources/source.dart';
import 'reader.dart';

class DetailsScreen extends StatefulWidget {
  final Manga manga;
  const DetailsScreen({super.key, required this.manga});
  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  List<Chapter>? chapters;
  String? error;
  bool desc = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final langs = context.read<AppState>().langs;
      final c = await sourceById(widget.manga.source).chapters(widget.manga, langs);
      if (mounted) setState(() => chapters = c);
    } catch (e) {
      if (mounted) setState(() => error = 'تعذر تحميل الفصول');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final m = widget.manga;
    final list = chapters == null ? null : (desc ? chapters!.reversed.toList() : chapters!);
    return Scaffold(
      appBar: AppBar(title: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis), actions: [
        IconButton(
          tooltip: 'ترتيب الفصول',
          icon: const Icon(Icons.swap_vert),
          onPressed: () => setState(() => desc = !desc),
        ),
        IconButton(
          tooltip: s.inLibrary(m) ? 'إزالة من المكتبة' : 'إضافة للمكتبة',
          icon: Icon(s.inLibrary(m) ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () => s.toggleLibrary(m),
        ),
      ]),
      body: ListView(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (m.cover.isNotEmpty) ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(m.cover, width: 110)),
            const SizedBox(width: 12),
            Expanded(child: Text(m.description.isEmpty ? 'لا يوجد وصف.' : m.description, maxLines: 8, overflow: TextOverflow.ellipsis)),
          ]),
        ),
        if (list != null && list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: Text(s.lastRead[m.id] == null ? 'ابدأ القراءة' : 'أكمل القراءة'),
              onPressed: () {
                final all = chapters!;
                final last = s.lastRead[m.id];
                var i = last == null ? 0 : all.indexWhere((c) => c.id == last);
                if (i < 0) i = 0;
                _open(all, i);
              },
            ),
          ),
        if (error != null) Padding(padding: const EdgeInsets.all(14), child: Text(error!)),
        if (list == null && error == null) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
        if (list != null && list.isEmpty) const Padding(padding: EdgeInsets.all(14), child: Text('لا توجد فصول باللغات المختارة. غيّر اللغات من الإعدادات.')),
        if (list != null)
          for (final c in list)
            ListTile(
              title: Text(c.title, style: TextStyle(color: s.read.contains(c.id) ? Theme.of(context).disabledColor : null)),
              subtitle: Text(c.lang),
              trailing: s.read.contains(c.id) ? const Icon(Icons.check, size: 18) : null,
              onTap: () => _open(chapters!, chapters!.indexOf(c)),
            ),
      ]),
    );
  }

  void _open(List<Chapter> all, int i) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(manga: widget.manga, chapters: all, index: i)));
}
