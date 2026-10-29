import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  late SharedPreferences _p;
  List<Manga> library = [];
  Set<String> read = {};
  Map<String, String> lastRead = {}; // mangaId -> chapterId
  List<String> langs = ['ar', 'en'];
  String readerMode = 'webtoon'; // webtoon | rtl | ltr
  bool dark = true;

  Future<void> init() async {
    _p = await SharedPreferences.getInstance();
    library = (json.decode(_p.getString('lib') ?? '[]') as List).map((e) => Manga.fromJson(e)).toList();
    read = (_p.getStringList('read') ?? []).toSet();
    lastRead = Map<String, String>.from(json.decode(_p.getString('last') ?? '{}'));
    langs = _p.getStringList('langs') ?? langs;
    readerMode = _p.getString('mode') ?? readerMode;
    dark = _p.getBool('dark') ?? true;
  }

  bool inLibrary(Manga m) => library.any((x) => x.id == m.id);
  void toggleLibrary(Manga m) {
    inLibrary(m) ? library.removeWhere((x) => x.id == m.id) : library.add(m);
    _p.setString('lib', json.encode(library.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  void markRead(Manga m, Chapter c) {
    read.add(c.id);
    lastRead[m.id] = c.id;
    _p.setStringList('read', read.toList());
    _p.setString('last', json.encode(lastRead));
    notifyListeners();
  }

  void setLangs(List<String> l) { langs = l; _p.setStringList('langs', l); notifyListeners(); }
  void setMode(String m) { readerMode = m; _p.setString('mode', m); notifyListeners(); }
  void setDark(bool v) { dark = v; _p.setBool('dark', v); notifyListeners(); }
}
