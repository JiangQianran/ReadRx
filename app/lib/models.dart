import 'package:flutter/material.dart';

List<String> _strList(dynamic v) =>
    v is List ? v.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList() : <String>[];

String _str(dynamic v) => v == null ? '' : v.toString().trim();

/// 一种药（识别结果 / 药箱里的药）
class Medicine {
  Medicine({
    required this.id,
    this.name = '',
    this.genericName = '',
    this.manufacturer = '',
    this.specification = '',
    this.expiryRaw = '',
    this.expiryDate,
    this.expiryNote = '',
    this.frequency = '',
    this.amount = '',
    this.method = '',
    this.usageNotes = '',
    this.indications = '',
    this.sideEffects = const [],
    this.contraindications = const [],
    this.cautions = const [],
    this.simpleSummary = '',
    this.speechText = '',
    this.missing = const [],
    this.aiFilled = const [],
    this.recognized = true,
    this.isMock = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String genericName;
  String manufacturer;
  String specification;
  String expiryRaw;
  DateTime? expiryDate;
  String expiryNote;
  String frequency;
  String amount;
  String method;
  String usageNotes;
  String indications;
  List<String> sideEffects;
  List<String> contraindications;
  List<String> cautions;
  String simpleSummary;
  String speechText;
  List<String> missing;

  /// 照片里没有、由 AI 按药学常识补充的项目：usage / indications / sideEffects / contraindications / cautions / simpleSummary
  List<String> aiFilled;
  bool recognized;
  bool isMock;
  DateTime createdAt;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (genericName.isNotEmpty) return genericName;
    return '未命名药品';
  }

  /// 用于相克查询时的名称：优先通用名
  String get queryName => genericName.isNotEmpty ? genericName : name;

  String get usageText => [amount, frequency].where((s) => s.isNotEmpty).join('，');

  /// 没有后端给出朗读文本时，自己拼一段
  String get textForSpeech {
    if (speechText.isNotEmpty) return speechText;
    final parts = <String>['药名：$displayName'];
    if (expiryDate != null) {
      parts.add('有效期到${expiryDate!.year}年${expiryDate!.month}月${expiryDate!.day}日');
    }
    if (usageText.isNotEmpty) parts.add('用法：$usageText');
    if (method.isNotEmpty) parts.add(method);
    if (sideEffects.isNotEmpty) parts.add('可能的副作用：${sideEffects.join('，')}');
    if (cautions.isNotEmpty) parts.add('注意：${cautions.join('，')}');
    return parts.join('。');
  }

  static int _seq = 0;

  /// 一次识别出多种药时，同一毫秒内也要生成不同的 id
  static String newId() => '${DateTime.now().millisecondsSinceEpoch}_${_seq++}';

  /// 从后端 /api/parse 结果中的一种药创建
  factory Medicine.fromApi(Map<String, dynamic> j) {
    final expiry = (j['expiry'] as Map?) ?? {};
    final usage = (j['usage'] as Map?) ?? {};
    return Medicine(
      id: newId(),
      name: _str(j['name']),
      genericName: _str(j['genericName']),
      manufacturer: _str(j['manufacturer']),
      specification: _str(j['specification']),
      expiryRaw: _str(expiry['raw']),
      expiryDate: DateTime.tryParse(_str(expiry['date'])),
      expiryNote: _str(expiry['note']),
      frequency: _str(usage['frequency']),
      amount: _str(usage['amount']),
      method: _str(usage['method']),
      usageNotes: _str(usage['notes']),
      indications: _str(j['indications']),
      sideEffects: _strList(j['sideEffects']),
      contraindications: _strList(j['contraindications']),
      cautions: _strList(j['cautions']),
      simpleSummary: _str(j['simpleSummary']),
      speechText: _str(j['speechText']),
      missing: _strList(j['missing']),
      aiFilled: _strList(j['aiFilled']),
      recognized: j['recognized'] != false,
      isMock: j['mock'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'genericName': genericName,
        'manufacturer': manufacturer,
        'specification': specification,
        'expiryRaw': expiryRaw,
        'expiryDate': expiryDate?.toIso8601String(),
        'expiryNote': expiryNote,
        'frequency': frequency,
        'amount': amount,
        'method': method,
        'usageNotes': usageNotes,
        'indications': indications,
        'sideEffects': sideEffects,
        'contraindications': contraindications,
        'cautions': cautions,
        'simpleSummary': simpleSummary,
        'speechText': speechText,
        'missing': missing,
        'aiFilled': aiFilled,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Medicine.fromJson(Map<String, dynamic> j) => Medicine(
        id: _str(j['id']),
        name: _str(j['name']),
        genericName: _str(j['genericName']),
        manufacturer: _str(j['manufacturer']),
        specification: _str(j['specification']),
        expiryRaw: _str(j['expiryRaw']),
        expiryDate: DateTime.tryParse(_str(j['expiryDate'])),
        expiryNote: _str(j['expiryNote']),
        frequency: _str(j['frequency']),
        amount: _str(j['amount']),
        method: _str(j['method']),
        usageNotes: _str(j['usageNotes']),
        indications: _str(j['indications']),
        sideEffects: _strList(j['sideEffects']),
        contraindications: _strList(j['contraindications']),
        cautions: _strList(j['cautions']),
        simpleSummary: _str(j['simpleSummary']),
        speechText: _str(j['speechText']),
        missing: _strList(j['missing']),
        aiFilled: _strList(j['aiFilled']),
        createdAt: DateTime.tryParse(_str(j['createdAt'])),
      );
}

/// 用药提醒：一种药，每天若干个时间点
class Reminder {
  Reminder({
    required this.id,
    required this.medicineName,
    this.medicineId,
    this.dosage = '',
    required this.times,
    this.enabled = true,
  });

  /// 通知 id = id * 10 + 第几个时间点，所以每个提醒最多 10 个时间点
  static const maxTimes = 10;

  final int id;
  String? medicineId;
  String medicineName;
  String dosage;
  List<TimeOfDay> times;
  bool enabled;

  static int newId() => DateTime.now().millisecondsSinceEpoch ~/ 1000 % 100000000;

  static String formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 时间所在的时段，如 08:00 → 早上
  static String periodOf(TimeOfDay t) {
    final h = t.hour;
    if (h < 5) return '凌晨';
    if (h < 11) return '早上';
    if (h < 14) return '中午';
    if (h < 17) return '下午';
    if (h < 19) return '傍晚';
    return '晚上';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineId': medicineId,
        'medicineName': medicineName,
        'dosage': dosage,
        'times': times.map(formatTime).toList(),
        'enabled': enabled,
      };

  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: (j['id'] as num).toInt(),
        medicineId: j['medicineId'] as String?,
        medicineName: _str(j['medicineName']),
        dosage: _str(j['dosage']),
        times: _strList(j['times']).map((s) {
          final p = s.split(':');
          return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
        }).toList(),
        enabled: j['enabled'] != false,
      );
}

/// 相克查询结果中的一条
class InteractionItem {
  InteractionItem({required this.a, required this.b, required this.level, this.reason = '', this.advice = ''});

  final String a;
  final String b;

  /// 禁止 / 慎用 / 无明显风险 / 不确定
  final String level;
  final String reason;
  final String advice;

  factory InteractionItem.fromJson(Map<String, dynamic> j) => InteractionItem(
        a: _str(j['a']),
        b: _str(j['b']),
        level: _str(j['level']).isEmpty ? '不确定' : _str(j['level']),
        reason: _str(j['reason']),
        advice: _str(j['advice']),
      );
}

class InteractionResult {
  InteractionResult({required this.items, this.summary = '', this.speechText = '', this.normalized = const [], this.isMock = false});

  final List<InteractionItem> items;
  final String summary;
  final String speechText;

  /// 例如 "泰诺 → 对乙酰氨基酚"
  final List<String> normalized;
  final bool isMock;

  factory InteractionResult.fromJson(Map<String, dynamic> j) => InteractionResult(
        items: ((j['results'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => InteractionItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        summary: _str(j['summary']),
        speechText: _str(j['speechText']),
        normalized: ((j['normalized'] as List?) ?? [])
            .whereType<Map>()
            .where((n) => _str(n['input']).isNotEmpty && _str(n['name']).isNotEmpty && _str(n['input']) != _str(n['name']))
            .map((n) => '${_str(n['input'])} → ${_str(n['name'])}')
            .toList(),
        isMock: j['mock'] == true,
      );
}
