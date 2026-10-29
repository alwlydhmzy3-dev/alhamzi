import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

/// واجهة المصدر: أي مصدر قانوني/مرخص تقدر تضيفه بتنفيذ هذه الواجهة وتسجيله في [allSources].
abstract class MangaSource {
  String get id;
  String get name;
  Future<List<Manga>> popular({int offset = 0, List<String> langs = const []});
  Future<List<Manga>> search(String query, {int offset = 0, List<String> langs = const []});
  Future<List<Chapter>> chapters(Manga m, List<String> langs);
  Future<List<PageRef>> pages(Chapter c);
}

final List<MangaSource> allSources = [MangaDexSource()];
MangaSource sourceById(String id) => allSources.firstWhere((s) => s.id == id, orElse: () => allSources.first);

class MangaDexSource implements MangaSource {
  static const _api = 'https://api.mangadex.org';
  @override
  String get id => 'mangadex';
  @override
  String get name => 'MangaDex';

  Future<Map<String, dynamic>> _get(String path, Map<String, dynamic> q) async {
    final uri = Uri.parse('$_api$path').replace(queryParameters: q);
    final r = await http.get(uri, headers: {'User-Agent': 'Alhamzi/1.0'}).timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) throw Exception('خطأ ${r.statusCode}');
    return json.decode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }

  String _pick(dynamic m) {
    if (m is! Map || m.isEmpty) return '';
    return (m['ar'] ?? m['en'] ?? m.values.first).toString();
  }

  Manga _parse(Map d) {
    final a = d['attributes'] as Map;
    String cover = '';
    for (final r in (d['relationships'] as List)) {
      if (r['type'] == 'cover_art' && r['attributes'] != null) {
        cover = 'https://uploads.mangadex.org/covers/${d['id']}/${r['attributes']['fileName']}.256.jpg';
      }
    }
    return Manga(id: d['id'], title: _pick(a['title']), cover: cover, description: _pick(a['description']), source: id);
  }

  Map<String, dynamic> _base(int offset, List<String> langs) => {
        'limit': '24',
        'offset': '$offset',
        'includes[]': ['cover_art'],
        'contentRating[]': ['safe', 'suggestive'],
        if (langs.isNotEmpty) 'availableTranslatedLanguage[]': langs,
      };

  @override
  Future<List<Manga>> popular({int offset = 0, List<String> langs = const []}) async {
    final j = await _get('/manga', {..._base(offset, langs), 'order[followedCount]': 'desc', 'hasAvailableChapters': 'true'});
    return (j['data'] as List).map((e) => _parse(e)).toList();
  }

  @override
  Future<List<Manga>> search(String query, {int offset = 0, List<String> langs = const []}) async {
    final j = await _get('/manga', {..._base(offset, langs), 'title': query, 'order[relevance]': 'desc'});
    return (j['data'] as List).map((e) => _parse(e)).toList();
  }

  @override
  Future<List<Chapter>> chapters(Manga m, List<String> langs) async {
    final out = <Chapter>[];
    int offset = 0;
    while (true) {
      final j = await _get('/manga/${m.id}/feed', {
        'limit': '500',
        'offset': '$offset',
        'order[chapter]': 'asc',
        'contentRating[]': ['safe', 'suggestive'],
        if (langs.isNotEmpty) 'translatedLanguage[]': langs,
      });
      final data = j['data'] as List;
      for (final c in data) {
        final a = c['attributes'];
        if (a['externalUrl'] != null || (a['pages'] ?? 0) == 0) continue;
        final num = double.tryParse('${a['chapter']}') ?? 0;
        final t = (a['title'] ?? '').toString();
        out.add(Chapter(id: c['id'], title: t.isEmpty ? 'الفصل ${a['chapter'] ?? '؟'}' : 'الفصل ${a['chapter'] ?? '؟'} - $t', lang: a['translatedLanguage'] ?? '', number: num));
      }
      offset += data.length;
      if (data.length < 500 || offset >= (j['total'] ?? 0)) break;
    }
    return out;
  }

  @override
  Future<List<PageRef>> pages(Chapter c) async {
    final j = await _get('/at-home/server/${c.id}', {});
    final base = j['baseUrl'];
    final hash = j['chapter']['hash'];
    return (j['chapter']['data'] as List).map((f) => PageRef.url('$base/data/$hash/$f')).toList();
  }
}
