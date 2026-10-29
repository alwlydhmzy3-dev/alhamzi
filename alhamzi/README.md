# الحمزي (Alhamzi)

قارئ مانجا / مانهوا / ويب تون بـ Flutter (أندرويد + iOS) — بدون إعلانات، بأذونات قليلة (إنترنت فقط).

## التشغيل
```
flutter create --org com.alhamzi --project-name alhamzi .
flutter pub get
flutter run
```
(الأمر الأول يولّد مجلدي android/ios وينسخ فوقهما lib و pubspec الموجودين.)
- أندرويد: تأكد من وجود `<uses-permission android:name="android.permission.INTERNET"/>` في `android/app/src/main/AndroidManifest.xml` للنسخة النهائية.
- iOS: يحتاج Mac + Xcode.

## المزايا
- استكشاف وبحث (MangaDex عبر واجهته الرسمية) مع تمرير لا نهائي
- قارئ: ويب تون عمودي بدون فراغات / مانجا RTL / كوميك LTR، تكبير بالقرص، فصل تالٍ
- مكتبة، تتبع الفصول المقروءة، "أكمل القراءة"
- فتح ملفات CBZ/ZIP المحلية
- فلترة لغات الفصول (عربي افتراضياً + إنجليزي)، وضع داكن، واجهة عربية RTL

## إضافة مصدر جديد
نفّذ `MangaSource` في `lib/sources/source.dart` وأضفه إلى `allSources`. أضف فقط مصادر لديك ترخيص أو حق قانوني لاستخدامها.

## خارطة الطريق
تحميل للقراءة دون إنترنت، مزامنة AniList/MAL، قفل التطبيق ووضع التخفي، تمرير تلقائي، إشعارات الفصول الجديدة.
