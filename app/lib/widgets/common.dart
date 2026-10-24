import 'package:flutter/material.dart';

import '../services/expiry.dart';
import '../services/tts.dart';

/// 带标题和图标的信息卡片
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.icon, required this.title, required this.child, this.color, this.trailing});

  final IconData icon;
  final String title;
  final Widget child;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: c, size: 26),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c))),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// 「AI 补充」小标签：标在照片里没有、由 AI 按常识补充的内容旁边
class AiBadge extends StatelessWidget {
  const AiBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Colors.indigo.shade600;
    return Tooltip(
      message: '照片里没有这部分，由 AI 按常规用法补充，请以说明书为准',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: c),
            const SizedBox(width: 4),
            Text('AI 补充', style: TextStyle(fontSize: 14, color: c, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

/// 固定在页面底部的操作栏（白底、上方淡阴影），放在 Scaffold.bottomNavigationBar
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: child),
      ),
    );
  }
}

/// 一行「标签：内容」
class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: '$label：', style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: value),
        ]),
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

/// 圆点列表
class BulletList extends StatelessWidget {
  const BulletList(this.items, {super.key, this.empty = '说明书中未提及'});
  final List<String> items;
  final String empty;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge;
    if (items.isEmpty) return Text(empty, style: style?.copyWith(color: Colors.grey.shade600));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('•  ', style: style),
                Expanded(child: Text(s, style: style)),
              ],
            ),
          ),
      ],
    );
  }
}

/// 有效期徽章
class ExpiryBadge extends StatelessWidget {
  const ExpiryBadge(this.date, {super.key, this.large = false});
  final DateTime? date;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final c = Expiry.color(date);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 14 : 10, vertical: large ? 8 : 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Expiry.icon(date), color: c, size: large ? 24 : 18),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              Expiry.label(date),
              style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: large ? 18 : 15),
            ),
          ),
        ],
      ),
    );
  }
}

/// 朗读按钮：点击朗读，再点停止
class SpeakButton extends StatelessWidget {
  const SpeakButton({super.key, required this.text, this.label = '语音朗读'});
  final String text;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: TtsService.instance.speaking,
      builder: (context, speaking, _) {
        final active = speaking == text;
        return FilledButton.icon(
          onPressed: text.trim().isEmpty ? null : () => TtsService.instance.toggle(text),
          icon: Icon(active ? Icons.stop_circle_outlined : Icons.volume_up, size: 28),
          label: Text(active ? '停止朗读' : label),
          style: active ? FilledButton.styleFrom(backgroundColor: Colors.orange.shade800) : null,
        );
      },
    );
  }
}

/// 免责声明
class Disclaimer extends StatelessWidget {
  const Disclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        '以上内容由 AI 根据照片或知识生成，仅供参考，可能有误。用药请以说明书和医生、药师的意见为准。',
        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 空状态提示
class EmptyHint extends StatelessWidget {
  const EmptyHint({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

void showMessage(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(fontSize: 17))));
}
