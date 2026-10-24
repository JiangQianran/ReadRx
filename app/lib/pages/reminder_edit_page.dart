import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/notifications.dart';
import '../widgets/common.dart';

/// 添加 / 修改用药提醒
class ReminderEditPage extends StatefulWidget {
  const ReminderEditPage({super.key, this.reminder, this.medicine});

  /// 修改已有提醒时传入
  final Reminder? reminder;

  /// 从药品详情页进入时传入，自动填好药名和用量
  final Medicine? medicine;

  @override
  State<ReminderEditPage> createState() => _ReminderEditPageState();
}

class _ReminderEditPageState extends State<ReminderEditPage> {
  final state = AppState.instance;
  late final _name = TextEditingController();
  late final _dosage = TextEditingController();
  String? _medicineId;
  List<TimeOfDay> _times = [];

  static const _presets = <({IconData icon, String label, TimeOfDay time})>[
    (icon: Icons.wb_sunny_outlined, label: '早上', time: TimeOfDay(hour: 8, minute: 0)),
    (icon: Icons.lunch_dining_outlined, label: '中午', time: TimeOfDay(hour: 12, minute: 0)),
    (icon: Icons.wb_twilight, label: '傍晚', time: TimeOfDay(hour: 18, minute: 0)),
    (icon: Icons.bedtime_outlined, label: '睡前', time: TimeOfDay(hour: 21, minute: 0)),
  ];

  bool _has(TimeOfDay t) => _times.any((e) => e.hour == t.hour && e.minute == t.minute);

  void _togglePreset(TimeOfDay t) {
    if (_has(t)) {
      setState(() => _times.removeWhere((e) => e.hour == t.hour && e.minute == t.minute));
    } else {
      _addTime(t);
    }
  }

  @override
  void initState() {
    super.initState();
    final r = widget.reminder;
    if (r != null) {
      _name.text = r.medicineName;
      _dosage.text = r.dosage;
      _medicineId = r.medicineId;
      _times = [...r.times];
    } else if (widget.medicine != null) {
      _applyMedicine(widget.medicine!);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _dosage.dispose();
    super.dispose();
  }

  /// 根据说明书里的「每日 N 次」推荐时间
  void _applyMedicine(Medicine m) {
    _medicineId = m.id;
    _name.text = m.displayName;
    _dosage.text = m.amount;
    final f = m.frequency;
    if (RegExp(r'(3|三)\s*次').hasMatch(f)) {
      _times = const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 12, minute: 0), TimeOfDay(hour: 18, minute: 0)];
    } else if (RegExp(r'(2|两|二)\s*次').hasMatch(f)) {
      _times = const [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 20, minute: 0)];
    } else if (RegExp(r'(1|一)\s*次').hasMatch(f)) {
      _times = const [TimeOfDay(hour: 8, minute: 0)];
    }
    _times = [..._times];
  }

  void _addTime(TimeOfDay t) {
    if (_times.length >= Reminder.maxTimes) return;
    if (_times.any((e) => e.hour == t.hour && e.minute == t.minute)) return;
    setState(() {
      _times.add(t);
      _times.sort((a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute));
    });
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      helpText: '选择吃药时间',
      initialEntryMode: TimePickerEntryMode.input,
    );
    if (t != null) _addTime(t);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return showMessage(context, '请填写药名');
    if (_times.isEmpty) return showMessage(context, '请至少添加一个时间');

    await NotificationService.instance.requestPermissions();
    final r = widget.reminder ?? Reminder(id: Reminder.newId(), medicineName: name, times: []);
    r
      ..medicineName = name
      ..medicineId = _medicineId
      ..dosage = _dosage.text.trim()
      ..times = _times
      ..enabled = true;
    try {
      await state.saveReminder(r);
    } catch (e) {
      if (mounted) showMessage(context, '设置提醒失败：$e');
      return;
    }
    if (!mounted) return;
    showMessage(context, '提醒已设置，每天 ${_times.map(Reminder.formatTime).join('、')} 提醒');
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('删除这个提醒？'),
        content: Text('删除后「${_name.text}」将不再提醒。', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteReminder(widget.reminder!);
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _input(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _hint(String s) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(s, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
      );

  @override
  Widget build(BuildContext context) {
    final meds = state.medicines;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? '添加提醒' : '修改提醒'),
        actions: [
          if (widget.reminder != null)
            IconButton(tooltip: '删除', iconSize: 28, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            icon: Icons.medication_outlined,
            title: '吃什么药',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (meds.isNotEmpty) ...[
                  _hint('从药箱里选'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in meds)
                        ChoiceChip(
                          label: Text(m.displayName),
                          labelStyle: TextStyle(
                            fontSize: 17,
                            color: _medicineId == m.id ? Colors.white : Colors.grey.shade800,
                            fontWeight: _medicineId == m.id ? FontWeight.w600 : FontWeight.normal,
                          ),
                          selected: _medicineId == m.id,
                          showCheckmark: false,
                          selectedColor: primary,
                          backgroundColor: Colors.grey.shade100,
                          side: BorderSide(color: _medicineId == m.id ? primary : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          onSelected: (_) => setState(() => _applyMedicine(m)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _name,
                  style: const TextStyle(fontSize: 18),
                  decoration: _input('药名'),
                  onChanged: (_) => _medicineId = null,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _dosage,
                  style: const TextStyle(fontSize: 18),
                  decoration: _input('每次吃多少', hint: '如 每次1片'),
                ),
              ],
            ),
          ),
          SectionCard(
            icon: Icons.alarm,
            title: '每天几点提醒',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_times.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Text('还没有添加时间，点下面的时段或「自定义时间」', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final t in _times) _TimeTile(time: t, onDelete: () => setState(() => _times.remove(t))),
                    ],
                  ),
                const SizedBox(height: 18),
                _hint('常用时段（点一下添加，再点取消）'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in _presets)
                      FilterChip(
                        avatar: Icon(p.icon, size: 22, color: _has(p.time) ? Colors.white : primary),
                        label: Text('${p.label} ${Reminder.formatTime(p.time)}'),
                        labelStyle: TextStyle(
                          fontSize: 17,
                          color: _has(p.time) ? Colors.white : Colors.grey.shade800,
                          fontWeight: _has(p.time) ? FontWeight.w600 : FontWeight.normal,
                        ),
                        selected: _has(p.time),
                        showCheckmark: false,
                        selectedColor: primary,
                        backgroundColor: Colors.grey.shade100,
                        side: BorderSide(color: _has(p.time) ? primary : Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                        onSelected: (_) => _togglePreset(p.time),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.more_time, size: 26),
                  label: const Text('自定义时间'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check, size: 28),
          label: const Text('保存提醒'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
        ),
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({required this.time, required this.onDelete});
  final TimeOfDay time;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Reminder.formatTime(time), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary, height: 1.2)),
              Text(Reminder.periodOf(time), style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
            ],
          ),
          IconButton(
            tooltip: '删除这个时间',
            onPressed: onDelete,
            icon: Icon(Icons.close, size: 22, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
