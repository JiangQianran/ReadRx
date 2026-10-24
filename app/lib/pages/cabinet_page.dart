import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../services/expiry.dart';
import '../widgets/common.dart';
import 'medicine_detail_page.dart';

/// 我的药箱：过期、快过期的排在前面，顶部可按状态筛选
class CabinetPage extends StatefulWidget {
  const CabinetPage({super.key, this.onGoScan});
  final VoidCallback? onGoScan;

  @override
  State<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends State<CabinetPage> {
  /// null 表示显示全部
  ExpiryStatus? _filter;

  static int _rank(Medicine m) {
    switch (Expiry.status(m.expiryDate)) {
      case ExpiryStatus.expired:
        return 0;
      case ExpiryStatus.soon:
        return 1;
      case ExpiryStatus.unknown:
        return 2;
      case ExpiryStatus.ok:
        return 3;
    }
  }

  void _toggle(ExpiryStatus? s) => setState(() => _filter = _filter == s ? null : s);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final meds = [...AppState.instance.medicines]..sort((a, b) => _rank(a).compareTo(_rank(b)));
        if (meds.isEmpty) return _buildEmpty();
        final expired = meds.where((m) => Expiry.status(m.expiryDate) == ExpiryStatus.expired).length;
        final soon = meds.where((m) => Expiry.status(m.expiryDate) == ExpiryStatus.soon).length;
        final shown = _filter == null ? meds : meds.where((m) => Expiry.status(m.expiryDate) == _filter).toList();
        final primary = Theme.of(context).colorScheme.primary;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: '全部',
                    count: meds.length,
                    color: primary,
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: '快到期',
                    count: soon,
                    color: Colors.orange.shade800,
                    selected: _filter == ExpiryStatus.soon,
                    onTap: () => _toggle(ExpiryStatus.soon),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: '已过期',
                    count: expired,
                    color: Colors.red.shade700,
                    selected: _filter == ExpiryStatus.expired,
                    onTap: () => _toggle(ExpiryStatus.expired),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Text('没有这类药', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
              ),
            for (final m in shown) _MedicineTile(m),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    final primary = Theme.of(context).colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: primary.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: Icon(Icons.medical_services_outlined, size: 60, color: primary),
            ),
            const SizedBox(height: 20),
            Text('药箱还是空的', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade900)),
            const SizedBox(height: 8),
            Text('拍一拍药盒，识别后点「加入药箱」\n就能在这里看到', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, color: Colors.grey.shade600, height: 1.5)),
            if (widget.onGoScan != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: widget.onGoScan,
                icon: const Icon(Icons.photo_camera, size: 26),
                label: const Text('去拍照识药'),
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.count, required this.color, required this.selected, required this.onTap});
  final String label;
  final int count;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: selected ? Colors.white : color)),
              Text(label, style: TextStyle(fontSize: 16, color: selected ? Colors.white70 : Colors.grey.shade700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineTile extends StatelessWidget {
  const _MedicineTile(this.m);
  final Medicine m;

  @override
  Widget build(BuildContext context) {
    final c = Expiry.color(m.expiryDate);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicineDetailPage(medicine: m))),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
          child: Row(
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
                    ExpiryBadge(m.expiryDate),
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
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 30, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
