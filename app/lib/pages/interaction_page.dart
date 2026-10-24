import 'package:flutter/material.dart';

import '../app_state.dart';
import '../widgets/common.dart';
import 'interaction_result_page.dart';

/// 用药安全查询：药物与药物、药物与食物是否相克
class InteractionPage extends StatefulWidget {
  const InteractionPage({super.key});

  @override
  State<InteractionPage> createState() => _InteractionPageState();
}

class _InteractionPageState extends State<InteractionPage> {
  static const _commonFoods = ['酒', '西柚', '牛奶', '浓茶', '咖啡', '豆浆', '海鲜', '辛辣食物'];
  static final _splitter = RegExp(r'[,，、;；\s]+');

  final _selectedMeds = <String>{};
  final _selectedFoods = <String>{};
  final _otherDrugs = TextEditingController();
  final _otherFoods = TextEditingController();

  @override
  void dispose() {
    _otherDrugs.dispose();
    _otherFoods.dispose();
    super.dispose();
  }

  List<String> _split(String s) => s.split(_splitter).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  List<String> get _drugs => {..._selectedMeds, ..._split(_otherDrugs.text)}.toList();
  List<String> get _foods => {..._selectedFoods, ..._split(_otherFoods.text)}.toList();

  void _query() {
    FocusScope.of(context).unfocus();
    if (_drugs.isEmpty) {
      showMessage(context, '请至少选择或填写一种药');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InteractionResultPage(drugs: _drugs, foods: _foods)),
    );
  }

  Widget _title(String s) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Text(s, style: Theme.of(context).textTheme.titleMedium),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final meds = AppState.instance.medicines.map((m) => m.queryName).where((s) => s.isNotEmpty).toSet().toList();
        _selectedMeds.removeWhere((s) => !meds.contains(s));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _title('① 选择要吃的药'),
            if (meds.isEmpty)
              Text('药箱里还没有药，可以在下面直接输入药名', style: TextStyle(fontSize: 16, color: Colors.grey.shade600))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final name in meds)
                    FilterChip(
                      label: Text(name, style: const TextStyle(fontSize: 17)),
                      selected: _selectedMeds.contains(name),
                      onSelected: (v) => setState(() => v ? _selectedMeds.add(name) : _selectedMeds.remove(name)),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherDrugs,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(labelText: '其他药（多个用逗号隔开）', hintText: '如 阿司匹林，头孢'),
            ),
            const SizedBox(height: 8),
            _title('② 想一起吃的食物 / 饮品（可不选）'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _commonFoods)
                  FilterChip(
                    label: Text(f, style: const TextStyle(fontSize: 17)),
                    selected: _selectedFoods.contains(f),
                    onSelected: (v) => setState(() => v ? _selectedFoods.add(f) : _selectedFoods.remove(f)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otherFoods,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(labelText: '其他食物', hintText: '如 香蕉，绿豆汤'),
            ),
            const SizedBox(height: 8),
            Text('只选一种药、不选食物时，会告诉你这种药不能和什么一起吃。', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _query,
              icon: const Icon(Icons.search, size: 28),
              label: const Text('查一查能不能一起吃'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
