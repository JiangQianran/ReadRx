import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:readrx/app_state.dart';
import 'package:readrx/models.dart';
import 'package:readrx/pages/cabinet_page.dart';
import 'package:readrx/pages/interaction_page.dart';
import 'package:readrx/pages/medicine_detail_page.dart';
import 'package:readrx/pages/scan_page.dart';
import 'package:readrx/services/expiry.dart';
import 'package:readrx/theme.dart';

final sampleApi = <String, dynamic>{
  'recognized': true,
  'name': '泰诺',
  'genericName': '对乙酰氨基酚缓释片',
  'expiry': {'raw': '有效期至 2027.05', 'date': '2027-05-31', 'note': ''},
  'usage': {'frequency': '每日3次', 'amount': '每次1片', 'method': '口服', 'notes': ''},
  'sideEffects': ['恶心'],
  'contraindications': ['过敏者禁用'],
  'cautions': ['不要喝酒'],
  'simpleSummary': '退烧止痛药',
  'speechText': '这是泰诺',
  'missing': [],
};

Widget wrap(Widget child) => MaterialApp(theme: buildTheme(), home: Scaffold(body: child));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    AppState.instance.medicines.clear();
  });

  group('有效期', () {
    final now = DateTime(2026, 10, 22);
    test('已过期', () => expect(Expiry.status(DateTime(2026, 10, 21), now: now), ExpiryStatus.expired));
    test('快过期', () => expect(Expiry.status(DateTime(2026, 12, 1), now: now), ExpiryStatus.soon));
    test('正常', () => expect(Expiry.status(DateTime(2027, 5, 31), now: now), ExpiryStatus.ok));
    test('未知', () => expect(Expiry.status(null, now: now), ExpiryStatus.unknown));
  });

  test('解析后端返回的药品并能存取', () {
    final m = Medicine.fromApi(sampleApi);
    expect(m.displayName, '泰诺');
    expect(m.queryName, '对乙酰氨基酚缓释片');
    expect(m.expiryDate, DateTime(2027, 5, 31));
    expect(m.usageText, '每次1片，每日3次');
    final back = Medicine.fromJson(m.toJson());
    expect(back.sideEffects, ['恶心']);
    expect(back.expiryDate, m.expiryDate);
  });

  test('提醒序列化', () {
    final r = Reminder(id: 123, medicineName: '泰诺', times: const [TimeOfDay(hour: 8, minute: 5)]);
    final back = Reminder.fromJson(r.toJson());
    expect(Reminder.formatTime(back.times.first), '08:05');
  });

  test('相克结果解析', () {
    final r = InteractionResult.fromJson({
      'normalized': [
        {'input': '泰诺', 'name': '对乙酰氨基酚', 'type': 'drug'}
      ],
      'results': [
        {'a': '对乙酰氨基酚', 'b': '酒精', 'level': '禁止', 'reason': '伤肝', 'advice': '别喝酒'}
      ],
      'summary': '不能喝酒',
    });
    expect(r.items.single.level, '禁止');
    expect(r.normalized.single, '泰诺 → 对乙酰氨基酚');
  });

  testWidgets('识药页面能显示', (tester) async {
    await tester.pumpWidget(wrap(const ScanPage()));
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('先拍照或选照片'), findsOneWidget);
  });

  testWidgets('识别结果页面显示并能加入药箱', (tester) async {
    tester.view.physicalSize = const Size(1080, 4000);
    addTearDown(tester.view.reset);
    final m = Medicine.fromApi(sampleApi);
    await tester.pumpWidget(MaterialApp(theme: buildTheme(), home: MedicineDetailPage(medicine: m, isNew: true)));
    expect(find.text('泰诺'), findsOneWidget);
    expect(find.text('朗读重点信息'), findsOneWidget);
    await tester.tap(find.text('加入药箱'));
    await tester.pumpAndSettle();
    expect(AppState.instance.medicines.length, 1);
  });

  testWidgets('药箱和相克页面能显示', (tester) async {
    await AppState.instance.saveMedicine(Medicine.fromApi(sampleApi));
    await tester.pumpWidget(wrap(const CabinetPage()));
    expect(find.textContaining('共 1 种药'), findsOneWidget);
    await tester.pumpWidget(wrap(const InteractionPage()));
    expect(find.text('对乙酰氨基酚缓释片'), findsOneWidget);
  });
}
