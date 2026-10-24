import 'package:flutter/material.dart';

import '../models.dart';
import '../services/expiry.dart';

/// 手动修改识别结果（AI 可能识别错）
class MedicineEditPage extends StatefulWidget {
  const MedicineEditPage({super.key, required this.medicine});
  final Medicine medicine;

  @override
  State<MedicineEditPage> createState() => _MedicineEditPageState();
}

class _MedicineEditPageState extends State<MedicineEditPage> {
  late final _name = TextEditingController(text: widget.medicine.name);
  late final _generic = TextEditingController(text: widget.medicine.genericName);
  late final _amount = TextEditingController(text: widget.medicine.amount);
  late final _frequency = TextEditingController(text: widget.medicine.frequency);
  late final _method = TextEditingController(text: widget.medicine.method);
  late DateTime? _expiry = widget.medicine.expiryDate;

  @override
  void dispose() {
    for (final c in [_name, _generic, _amount, _frequency, _method]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _expiry ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 15),
      helpText: '选择有效期截止日',
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (d != null) setState(() => _expiry = d);
  }

  void _save() {
    final old = widget.medicine;
    final usageChanged = old.amount != _amount.text.trim() || old.frequency != _frequency.text.trim() || old.method != _method.text.trim();
    final m = widget.medicine
      ..aiFilled = usageChanged ? old.aiFilled.where((k) => k != 'usage').toList() : old.aiFilled
      ..name = _name.text.trim()
      ..genericName = _generic.text.trim()
      ..amount = _amount.text.trim()
      ..frequency = _frequency.text.trim()
      ..method = _method.text.trim()
      // 手动改过后，朗读文本按新内容重新生成
      ..speechText = ''
      ..expiryDate = _expiry;
    Navigator.pop(context, m);
  }

  Widget _field(String label, TextEditingController c, {String? hint}) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextField(
          controller: c,
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(labelText: label, hintText: hint),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改药品信息')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _field('药名（商品名）', _name, hint: '如 泰诺'),
          _field('通用名', _generic, hint: '如 对乙酰氨基酚缓释片'),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: const Icon(Icons.event, size: 30),
              title: const Text('有效期至', style: TextStyle(fontSize: 18)),
              subtitle: Text(Expiry.format(_expiry), style: const TextStyle(fontSize: 18)),
              trailing: _expiry == null
                  ? const Icon(Icons.chevron_right)
                  : IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _expiry = null)),
              onTap: _pickDate,
            ),
          ),
          const SizedBox(height: 8),
          _field('每次用量', _amount, hint: '如 每次1片'),
          _field('服用次数', _frequency, hint: '如 每日3次'),
          _field('服用方法', _method, hint: '如 口服，饭后服用'),
          FilledButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
    );
  }
}
