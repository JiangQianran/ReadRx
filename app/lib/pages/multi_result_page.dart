import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/expiry.dart';
import '../widgets/common.dart';
import 'interaction_result_page.dart';
import 'medicine_detail_page.dart';

/// 一次识别出多种药时的结果列表
class MultiResultPage extends StatelessWidget {
  const MultiResultPage({super.key, required this.medicines});
  final List<Medicine> medicines;

  Future<void> _saveAll(BuildContext context) async {
    final state = AppState.instance;
    for (final m in medicines.reversed) {
      if (!state.contains(m)) await state.saveMedicine(m);
    }
    if (context.mounted) showMessage(context, '已把 ${medicines.length} 种药都加入药箱');
  }

  void _checkTogether(BuildContext context) {
    final names = medicines.map((m) => m.queryName).where((s) => s.isNotEmpty).toSet().toList();
    Navigator.push(context, MaterialPageRoute(builder: (_) => InteractionResultPage(drugs: names, foods: const [])));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final allSaved = medicines.every(state.contains);
        final expired = medicines.where((m) => Expiry.status(m.expiryDate) == ExpiryStatus.expired).length;
        return Scaffold(
          appBar: AppBar(title: const Text('识别结果')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (medicines.any((m) => m.isMock))
                Card(
                  color: Colors.amber.shade100,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('这是演示数据：服务器还没配置 DeepSeek API Key。', style: TextStyle(fontSize: 16)),
                  ),
                ),
              Text('认出了 ${medicines.length} 种药', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
              const SizedBox(height: 4),
              Text('点开每一种，可以看详细说明和朗读', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              if (expired > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Icon(Icons.dangerous_outlined, color: Colors.red.shade700, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('其中 $expired 种已过期，请不要再吃',
                            style: TextStyle(fontSize: 17, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              for (final m in medicines) _ResultTile(medicine: m, saved: state.contains(m)),
              const SizedBox(height: 4),
              OutlinedButton.icon(
                onPressed: () => _checkTogether(context),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56), backgroundColor: Colors.white),
                icon: const Icon(Icons.health_and_safety_outlined, size: 26),
                label: const Text('查这几种药能不能一起吃'),
              ),
              const Disclaimer(),
            ],
          ),
          bottomNavigationBar: BottomActionBar(
            child: FilledButton.icon(
              onPressed: allSaved ? null : () => _saveAll(context),
              icon: Icon(allSaved ? Icons.check : Icons.add_box_outlined, size: 26),
              label: Text(allSaved ? '已全部加入药箱' : '全部加入药箱'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(60)),
            ),
          ),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.medicine, required this.saved});
  final Medicine medicine;
  final bool saved;

  @override
  Widget build(BuildContext context) {
    final m = medicine;
    final c = Expiry.color(m.expiryDate);
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetailPage(medicine: m, isNew: true))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
                child: Icon(Icons.medication, color: c, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.displayName,
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    if (m.genericName.isNotEmpty && m.genericName != m.displayName)
                      Text(m.genericName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ExpiryBadge(m.expiryDate),
                        if (saved)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check, size: 16, color: primary),
                                const SizedBox(width: 4),
                                Text('已加入药箱', style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (m.usageText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Expanded(child: Text(m.usageText, style: TextStyle(fontSize: 16, color: Colors.grey.shade700))),
                        ],
                      ),
                    ],
                    if (m.simpleSummary.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(m.simpleSummary, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Icon(Icons.chevron_right, size: 30, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
