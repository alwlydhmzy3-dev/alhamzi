import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import '../models.dart';
import '../state.dart';
import '../sources/source.dart';
import 'details.dart';
import 'reader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [const ExploreTab(), const LibraryTab(), const SettingsTab()];
    return Scaffold(
      body: SafeArea(child: pages[tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'استكشاف'),
          NavigationDestination(icon: Icon(Icons.collections_bookmark_outlined), label: 'مكتبتي'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

Widget mangaGrid(List<Manga> items, {ScrollController? ctrl, required void Function(Manga) onTap}) {
  return GridView.builder(
    controller: ctrl,
    padding: const EdgeInsets.all(10),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 160, childAspectRatio: 0.62, crossAxisSpacing: 10, mainAxisSpacing: 10),
    itemCount: items.length,
    itemBuilder: (_, i) {
      final m = items[i];
      return InkWell(
        onTap: () => onTap(m),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox.expand(
                child: m.cover.isEmpty
                    ? const ColoredBox(color: Colors.black26, child: Icon(Icons.image_not_supported))
                    : Image.network(m.cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black26)),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5)),
        ]),
      );
    },
  );
}

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});
  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final items = <Manga>[];
  final ctrl = ScrollController();
  final q = TextEditingController();
  bool loading = false, end = false;
  String query = '';
  String? error;
  MangaSource src = allSources.first;

  @override
  void initState() {
    super.initState();
    ctrl.addListener(() {
      if (ctrl.position.pixels > ctrl.position.maxScrollExtent - 400) _load();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  Future<void> _load({bool reset = false}) async {
    if (loading || (end && !reset)) return;
    final langs = context.read<AppState>().langs;
    setState(() { loading = true; error = null; if (reset) { items.clear(); end = false; } });
    try {
      final r = query.isEmpty ? await src.popular(offset: items.length, langs: langs) : await src.search(query, offset: items.length, langs: langs);
      items.addAll(r);
      if (r.length < 24) end = true;
    } catch (e) {
      error = 'تعذر التحميل. تحقق من الاتصال وحاول مرة ثانية.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> _openLocal() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['cbz', 'zip'], withData: true);
    if (r == null || r.files.single.bytes == null) return;
    final arc = ZipDecoder().decodeBytes(r.files.single.bytes!);
    final files = arc.files.where((f) => f.isFile && RegExp(r'\.(jpe?g|png|webp)$', caseSensitive: false).hasMatch(f.name)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final pages = files.map((f) => PageRef.bytes(f.content as dynamic)).toList();
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen.local(title: r.files.single.name, pages: pages)));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          Expanded(
            child: SearchBar(
              controller: q,
              hintText: 'ابحث عن مانجا أو مانهوا...',
              leading: const Icon(Icons.search),
              onSubmitted: (v) { query = v.trim(); _load(reset: true); },
            ),
          ),
          IconButton(tooltip: 'فتح ملف CBZ', onPressed: _openLocal, icon: const Icon(Icons.folder_open)),
        ]),
      ),
      if (error != null) Padding(padding: const EdgeInsets.all(12), child: Text(error!)),
      Expanded(child: mangaGrid(items, ctrl: ctrl, onTap: (m) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(manga: m))))),
      if (loading) const LinearProgressIndicator(),
    ]);
  }
}

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});
  @override
  Widget build(BuildContext context) {
    final lib = context.watch<AppState>().library;
    if (lib.isEmpty) return const Center(child: Text('مكتبتك فاضية. أضف أعمالك من صفحة الاستكشاف.'));
    return mangaGrid(lib, onTap: (m) => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(manga: m))));
  }
}

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(children: [
      const ListTile(title: Text('الحمزي', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), subtitle: Text('قارئ مانجا ومانهوا وويب تون • بدون إعلانات')),
      SwitchListTile(title: const Text('الوضع الداكن'), value: s.dark, onChanged: s.setDark),
      const Divider(),
      const ListTile(title: Text('وضع القراءة')),
      RadioListTile(title: const Text('ويب تون (تمرير عمودي)'), value: 'webtoon', groupValue: s.readerMode, onChanged: (v) => s.setMode(v!)),
      RadioListTile(title: const Text('مانجا (يمين لليسار)'), value: 'rtl', groupValue: s.readerMode, onChanged: (v) => s.setMode(v!)),
      RadioListTile(title: const Text('كوميك (يسار لليمين)'), value: 'ltr', groupValue: s.readerMode, onChanged: (v) => s.setMode(v!)),
      const Divider(),
      const ListTile(title: Text('لغات الفصول')),
      for (final l in const {'ar': 'العربية', 'en': 'English', 'ja': '日本語', 'ko': '한국어'}.entries)
        CheckboxListTile(
          title: Text(l.value),
          value: s.langs.contains(l.key),
          onChanged: (v) {
            final n = [...s.langs];
            v! ? n.add(l.key) : n.remove(l.key);
            s.setLangs(n);
          },
        ),
    ]);
  }
}
