import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../widgets/common.dart';
import 'reminder_edit_page.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  void _openEditor(BuildContext context, {Reminder? reminder}) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ReminderEditPage(reminder: reminder)));
  }

  @override
  Widget build(BuildContext context) {
    final state = AppState.instance;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final list = [...state.reminders]..sort((a, b) => a.medicineName.compareTo(b.medicineName));
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.alarm_add, size: 28),
              label: const Text('添加吃药提醒'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(64)),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty) const EmptyHint(icon: Icons.alarm_off, text: '还没有提醒\n点上面的按钮添加'),
            for (final r in list)
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _openEditor(context, reminder: r),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.medicineName, style: Theme.of(context).textTheme.titleLarge),
                              if (r.dosage.isNotEmpty) Text(r.dosage, style: const TextStyle(fontSize: 17)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  for (final t in r.times)
                                    Chip(
                                      avatar: const Icon(Icons.access_time, size: 20),
                                      label: Text(Reminder.formatTime(t), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2,
                          child: Switch(
                            value: r.enabled,
                            onChanged: (v) async {
                              r.enabled = v;
                              await state.saveReminder(r);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              color: Colors.blueGrey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('提醒不响怎么办？', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      '华为、小米、OPPO、vivo 等手机会自动关掉后台应用。请到手机「设置 → 应用 → ReadRx」里：\n'
                      '• 允许通知\n• 允许自启动 / 后台运行\n• 电池设置为「不限制」或「无限制」',
                      style: TextStyle(fontSize: 16, height: 1.6),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
