import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/expiry.dart';
import '../services/tts.dart';
import '../widgets/common.dart';
import 'medicine_edit_page.dart';
import 'reminder_edit_page.dart';

/// 识别结果 / 药品详情
class MedicineDetailPage extends StatefulWidget {
  const MedicineDetailPage({super.key, required this.medicine, this.isNew = false});
  final Medicine medicine;

  /// 刚识别出来、还没加入药箱
  final bool isNew;

  @override
  State<MedicineDetailPage> createState() => _MedicineDetailPageState();
}

class _MedicineDetailPageState extends State<MedicineDetailPage> {
  late Medicine m = widget.medicine;
  final state = AppState.instance;

  bool get _saved => state.contains(m);

  @override
  void initState() {
    super.initState();
    if (widget.isNew && state.autoSpeak) {
      WidgetsBinding.instance.addPostFrameCallback((_) => TtsService.instance.speak(m.textForSpeech));
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _save() async {
    await state.saveMedicine(m);
    if (mounted) {
      setState(() {});
      showMessage(context, '已加入药箱');
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<Medicine>(context, MaterialPageRoute(builder: (_) => MedicineEditPage(medicine: m)));
    if (updated == null) return;
    setState(() => m = updated);
    if (_saved) await state.saveMedicine(m);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('从药箱删除？'),
        content: Text('确定删除「${m.displayName}」吗？', style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteMedicine(m);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _addReminder() async {
    if (!_saved) await state.saveMedicine(m);
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ReminderEditPage(medicine: m)));
  }

  Widget? _aiBadge(List<String> keys) => keys.any(m.aiFilled.contains) ? const AiBadge() : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '识别结果' : '药品详情'),
        actions: [
          IconButton(tooltip: '修改', iconSize: 28, icon: const Icon(Icons.edit), onPressed: _edit),
          if (_saved) IconButton(tooltip: '删除', iconSize: 28, icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (m.isMock)
            Card(
              color: Colors.amber.shade100,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('这是演示数据：服务器还没配置 DeepSeek API Key。', style: TextStyle(fontSize: 16)),
              ),
            ),
          _buildHeader(),
          SpeakButton(text: m.textForSpeech, label: '朗读重点信息'),
          const SizedBox(height: 12),
          _buildSummary(),
          _buildUsage(),
          SectionCard(
            icon: Icons.report_gmailerrorred,
            title: '可能的副作用',
            color: Colors.orange.shade800,
            trailing: _aiBadge(['sideEffects']),
            child: _TintedList(m.sideEffects, color: Colors.orange.shade800),
          ),
          SectionCard(
            icon: Icons.do_not_disturb_on_outlined,
            title: '禁忌和注意事项',
            color: Colors.red.shade700,
            trailing: _aiBadge(['contraindications', 'cautions']),
            child: _TintedList([...m.contraindications, ...m.cautions], color: Colors.red.shade700),
          ),
          _buildNotice(),
          const Disclaimer(),
        ],
      ),
      bottomNavigationBar: _buildActions(),
    );
  }

  /// 药名、有效期、规格厂家
  Widget _buildHeader() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final c = Expiry.color(m.expiryDate);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: scheme.primaryContainer,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: scheme.primary,
                  child: const Icon(Icons.medication, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: scheme.onPrimaryContainer)),
                      if (m.genericName.isNotEmpty && m.genericName != m.displayName)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(m.genericName, style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey.shade700)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 有效期：按状态着色的醒目区块
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withValues(alpha: 0.45), width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Expiry.icon(m.expiryDate), color: c, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Expiry.label(m.expiryDate), style: TextStyle(color: c, fontSize: 21, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('有效期至 ${Expiry.format(m.expiryDate)}', style: const TextStyle(fontSize: 18)),
                      if (m.expiryRaw.isNotEmpty)
                        Text('包装上写：${m.expiryRaw}', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                      if (m.expiryNote.isNotEmpty)
                        Text(m.expiryNote, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (m.specification.isNotEmpty || m.manufacturer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  if (m.specification.isNotEmpty) _MetaRow(icon: Icons.straighten, label: '规格', value: m.specification),
                  if (m.manufacturer.isNotEmpty) _MetaRow(icon: Icons.factory_outlined, label: '厂家', value: m.manufacturer),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 大白话说明 + 主治
  Widget _buildSummary() {
    final theme = Theme.of(context);
    if (m.simpleSummary.isEmpty && m.indications.isEmpty) return const SizedBox.shrink();
    return SectionCard(
      icon: Icons.chat_outlined,
      title: '这是什么药',
      trailing: _aiBadge(['simpleSummary', 'indications']),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (m.simpleSummary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(m.simpleSummary, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 19, height: 1.6)),
            ),
          if (m.indications.isNotEmpty) ...[
            const SizedBox(height: 10),
            InfoRow('主治', m.indications),
          ],
        ],
      ),
    );
  }

  /// 用法用量：每次 / 每天 两个大格子，下面是服用方法和注意
  Widget _buildUsage() {
    final empty = (m.amount + m.frequency + m.method + m.usageNotes).isEmpty;
    return SectionCard(
      icon: Icons.schedule,
      title: '怎么吃',
      trailing: _aiBadge(['usage']),
      child: empty
          ? const BulletList([])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (m.amount.isNotEmpty || m.frequency.isNotEmpty)
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _UsageTile(icon: Icons.medication_outlined, label: '每次吃', value: m.amount)),
                        const SizedBox(width: 10),
                        Expanded(child: _UsageTile(icon: Icons.repeat, label: '吃几次', value: m.frequency)),
                      ],
                    ),
                  ),
                if (m.method.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _MetaRow(icon: Icons.restaurant_outlined, label: '怎么服', value: m.method),
                ],
                if (m.usageNotes.isNotEmpty) _MetaRow(icon: Icons.info_outline, label: '注意', value: m.usageNotes),
              ],
            ),
    );
  }

  /// AI 补充说明和照片里缺的项目，合并成一张提示卡
  Widget _buildNotice() {
    if (m.aiFilled.isEmpty && m.missing.isEmpty) return const SizedBox.shrink();
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.indigo.shade600, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (m.aiFilled.isNotEmpty)
                    const Text('标有「AI 补充」的内容照片里没有拍到，是 AI 按这种药的常规用法补充的，具体请以说明书和医生的叮嘱为准。',
                        style: TextStyle(fontSize: 16, height: 1.5)),
                  if (m.aiFilled.isNotEmpty && m.missing.isNotEmpty) const SizedBox(height: 8),
                  if (m.missing.isNotEmpty)
                    Text('照片里没找到：${m.missing.join('、')}。可以补拍后重新识别，或点右上角 ✎ 手动填写。',
                        style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 固定在底部的操作按钮
  Widget _buildActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              if (!_saved) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.add_box_outlined, size: 26),
                    label: const Text('加入药箱'),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _saved
                    ? FilledButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.alarm_add, size: 26),
                        label: const Text('设置吃药提醒'),
                      )
                    : OutlinedButton.icon(
                        onPressed: _addReminder,
                        icon: const Icon(Icons.alarm_add, size: 26),
                        label: const Text('设提醒'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageTile extends StatelessWidget {
  const _UsageTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: c, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value,
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, height: 1.3)),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 3), child: Icon(icon, size: 20, color: Colors.grey.shade600)),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: '$label：', style: TextStyle(color: Colors.grey.shade700)),
                TextSpan(text: value),
              ]),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}

/// 带浅色底的条目列表，用于副作用、禁忌
class _TintedList extends StatelessWidget {
  const _TintedList(this.items, {required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const BulletList([]);
    final style = Theme.of(context).textTheme.bodyLarge;
    return Column(
      children: [
        for (final s in items)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(10)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9),
                  child: Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(s, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}
