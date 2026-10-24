import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models.dart';

/// 用药提醒：本地定时通知（不需要联网）
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _inited = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'medicine_reminder',
      '用药提醒',
      channelDescription: '按时吃药的提醒',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      ticker: '该吃药了',
    ),
    iOS: DarwinNotificationDetails(presentAlert: true, presentBanner: true, presentSound: true),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_inited) return;
    tzdata.initializeTimeZones();
    // 面向国内用户，固定使用北京时间
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _inited = true;
  }

  /// 申请通知权限（和安卓 12 以上的精确闹钟权限）。在用户点击「添加提醒」时调用
  Future<bool> requestPermissions() async {
    await init();
    try {
      if (Platform.isAndroid) {
        final granted = await _android?.requestNotificationsPermission() ?? true;
        final exact = await _android?.canScheduleExactNotifications() ?? true;
        if (!exact) await _android?.requestExactAlarmsPermission();
        return granted;
      }
      if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        return await ios?.requestPermissions(alert: true, sound: true, badge: false) ?? false;
      }
    } catch (e) {
      debugPrint('申请通知权限失败: $e');
    }
    return true;
  }

  tz.TZDateTime _nextInstance(TimeOfDay t) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, t.hour, t.minute);
    if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
    return at;
  }

  /// 按提醒设置每天重复的通知；会先取消旧的
  Future<void> schedule(Reminder r) async {
    await init();
    await cancel(r);
    if (!r.enabled) return;

    var mode = AndroidScheduleMode.exactAllowWhileIdle;
    if (Platform.isAndroid && (await _android?.canScheduleExactNotifications() ?? true) == false) {
      // 没有精确闹钟权限时退回普通模式，可能会晚几分钟
      mode = AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final body = r.dosage.isEmpty ? '请按时服药' : '本次用量：${r.dosage}';
    for (var i = 0; i < r.times.length && i < Reminder.maxTimes; i++) {
      await _plugin.zonedSchedule(
        id: r.id * 10 + i,
        title: '该吃药了：${r.medicineName}',
        body: body,
        scheduledDate: _nextInstance(r.times[i]),
        notificationDetails: _details,
        androidScheduleMode: mode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> cancel(Reminder r) async {
    await init();
    for (var i = 0; i < Reminder.maxTimes; i++) {
      await _plugin.cancel(id: r.id * 10 + i);
    }
  }

  /// 立即发一条测试通知，用来检查手机是否会拦截
  Future<void> showTest() async {
    await init();
    await _plugin.show(id: 1, title: 'ReadRx 测试提醒', body: '能看到这条，说明通知正常', notificationDetails: _details);
  }
}
