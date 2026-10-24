import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/api.dart';
import '../services/tts.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 相克查询结果页：打开后立即查询
class InteractionResultPage extends StatefulWidget {
  const InteractionResultPage({super.key, required this.drugs, required this.foods});
  final List<String> drugs;
  final List<String> foods;

  @override
  State<InteractionResultPage> createState() => _InteractionResultPageState();
}

class _InteractionResultPageState extends State<InteractionResultPage> {
  static const _levelOrder = ['禁止', '慎用', '不确定', '无明显风险'];

  bool _loading = true;
  InteractionResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _query();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _query() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final r = await AppState.instance.api.interaction(drugs: widget.drugs, foods: widget.foods);
      if (mounted) setState(() => _result = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = '出错了：$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static int _rank(String level) {
    final i = _levelOrder.indexOf(level);
    return i < 0 ? 2 : i;
  }

  static String _levelHint(String level) {
    switch (level) {
      case '禁止':
        return '不能一起吃';
      case '慎用':
        return '要小心，最好问医生';
      case '无明显风险':
        return '一般可以一起吃';
      default:
        return '暂时说不准，请问医生或药师';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('查询结果')),
      body: _loading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : _buildResult(_result!),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 5)),
          const SizedBox(height: 24),
          Text('AI 正在查询，请稍等…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('一般需要十几秒', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 72, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _query,
              icon: const Icon(Icons.refresh, size: 28),
              label: const Text('重新查询'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(InteractionResult r) {
    final items = [...r.items]..sort((x, y) => _rank(x.level).compareTo(_rank(y.level)));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (r.isMock)
          Card(
            color: Colors.amber.shade100,
            child: const Padding(padding: EdgeInsets.all(12), child: Text('这是演示数据：服务器还没配置 DeepSeek API Key。')),
          ),
        _buildQueryCard(),
        _buildSummaryCard(r, items),
        SpeakButton(text: r.speechText.isNotEmpty ? r.speechText : r.summary, label: '朗读结论'),
        const SizedBox(height: 16),
        if (r.normalized.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('已识别为：${r.normalized.join('；')}', style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
          ),
        if (items.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('逐项说明（${items.length} 项）', style: Theme.of(context).textTheme.titleMedium),
          ),
        for (final it in items) _buildItemCard(it),
        const Disclaimer(),
      ],
    );
  }

  /// 本次查了哪些东西
  Widget _buildQueryCard() {
    Widget chip(String s, IconData icon, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 4),
              Flexible(child: Text(s, style: TextStyle(fontSize: 17, color: c, fontWeight: FontWeight.w600))),
            ],
          ),
        );
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本次查询', style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in widget.drugs) chip(d, Icons.medication, primary),
                for (final f in widget.foods) chip(f, Icons.restaurant, Colors.brown.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 总结论：按最危险的一项着色
  Widget _buildSummaryCard(InteractionResult r, List<InteractionItem> items) {
    final worst = items.isEmpty ? '无明显风险' : items.first.level;
    final c = levelColor(worst);
    final counts = <String, int>{};
    for (final it in items) {
      counts[it.level] = (counts[it.level] ?? 0) + 1;
    }
    final summary = r.summary.isNotEmpty ? r.summary : (items.isEmpty ? '没有查到需要注意的组合。' : '');
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c, width: 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: c,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Icon(levelIcon(worst), color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('总结论', style: TextStyle(color: Colors.white70, fontSize: 15)),
                      Text(_levelHint(worst),
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.isNotEmpty) Text(summary, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.5)),
                if (counts.isNotEmpty) ...[
                  if (summary.isNotEmpty) const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final level in _levelOrder)
                        if (counts[level] != null) _LevelCount(level: level, count: counts[level]!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InteractionItem it) {
    final c = levelColor(it.level);
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.withValues(alpha: 0.5), width: 1.5)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 等级
          Container(
            color: c.withValues(alpha: 0.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(levelIcon(it.level), color: c, size: 28),
                const SizedBox(width: 8),
                Text(it.level, style: TextStyle(color: c, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_levelHint(it.level),
                      style: TextStyle(color: c, fontSize: 16), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A + B
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _NameTag(it.a),
                    Icon(Icons.add, size: 22, color: Colors.grey.shade600),
                    _NameTag(it.b),
                  ],
                ),
                if (it.reason.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _Labeled(icon: Icons.info_outline, label: '为什么', text: it.reason, color: Colors.grey.shade700),
                ],
                if (it.advice.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                    child: _Labeled(icon: Icons.lightbulb_outline, label: '怎么做', text: it.advice, color: c),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NameTag extends StatelessWidget {
  const _NameTag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.icon, required this.label, required this.text, required this.color});
  final IconData icon;
  final String label;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 3), child: Icon(icon, size: 22, color: color)),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: '$label：', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              TextSpan(text: text),
            ]),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _LevelCount extends StatelessWidget {
  const _LevelCount({required this.level, required this.count});
  final String level;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = levelColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(levelIcon(level), size: 18, color: c),
          const SizedBox(width: 4),
          Text('$level $count 项', style: TextStyle(fontSize: 16, color: c, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
