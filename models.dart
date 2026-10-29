import 'dart:typed_data';

class Manga {
  final String id, title, cover, description, source;
  Manga({required this.id, required this.title, required this.cover, required this.description, required this.source});
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'cover': cover, 'description': description, 'source': source};
  factory Manga.fromJson(Map<String, dynamic> j) => Manga(
      id: j['id'], title: j['title'], cover: j['cover'] ?? '', description: j['description'] ?? '', source: j['source']);
}

class Chapter {
  final String id, title, lang;
  final double number;
  Chapter({required this.id, required this.title, required this.lang, required this.number});
}

class PageRef {
  final String? url;
  final Uint8List? bytes;
  PageRef.url(this.url) : bytes = null;
  PageRef.bytes(this.bytes) : url = null;
}
