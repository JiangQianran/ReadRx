import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// 与 Node 后端通信
class ApiClient {
  ApiClient({required this.baseUrl, this.token = ''});

  final String baseUrl;
  final String token;

  Uri _uri(String path) {
    var base = baseUrl.trim();
    if (base.isEmpty) throw ApiException('还没有设置服务器地址，请到「设置」里填写');
    if (!base.startsWith('http')) base = 'http://$base';
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);
    return Uri.parse('$base$path');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=utf-8',
        if (token.isNotEmpty) 'x-app-token': token,
      };

  Future<Map<String, dynamic>> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request();
    } on TimeoutException {
      throw ApiException('等待太久了，请检查网络后重试');
    } on SocketException {
      throw ApiException('连不上服务器。请检查「设置」里的服务器地址，并确认手机和电脑连的是同一个 Wi-Fi');
    } on http.ClientException {
      throw ApiException('连不上服务器，请检查网络和服务器地址');
    } on ArgumentError {
      throw ApiException('服务器地址格式不对，应类似 http://192.168.1.5:3000');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('服务器返回的数据有误（状态码 ${res.statusCode}）');
    }
    if (res.statusCode >= 400) {
      throw ApiException(body['error']?.toString() ?? '请求失败（状态码 ${res.statusCode}）');
    }
    return body;
  }

  /// 测试连接，返回提示文字
  Future<String> health() async {
    final j = await _send(() => http.get(_uri('/api/health'), headers: _headers).timeout(const Duration(seconds: 8)));
    if (j['mock'] == true) return '连接成功（服务器处于演示模式，返回示例数据）';
    return '连接成功';
  }

  /// 识别药品：上传 1~6 张照片，照片里可能有多种药；没认出药品时返回空列表
  Future<List<Medicine>> parse(List<Uint8List> images) async {
    final payload = jsonEncode({
      'images': images.map((b) => 'data:image/jpeg;base64,${base64Encode(b)}').toList(),
    });
    final j = await _send(
      () => http.post(_uri('/api/parse'), headers: _headers, body: payload).timeout(const Duration(seconds: 150)),
    );
    final list = j['medicines'];
    if (list is List) {
      return list.whereType<Map>().map((e) => Medicine.fromApi(Map<String, dynamic>.from(e))).toList();
    }
    // 兼容旧版后端：只返回一种药
    final m = Medicine.fromApi(j);
    return m.recognized ? [m] : [];
  }

  /// 相克查询
  Future<InteractionResult> interaction({
    required List<String> drugs,
    List<String> foods = const [],
    String question = '',
  }) async {
    final payload = jsonEncode({'drugs': drugs, 'foods': foods, 'question': question});
    final j = await _send(
      () => http.post(_uri('/api/interaction'), headers: _headers, body: payload).timeout(const Duration(seconds: 90)),
    );
    return InteractionResult.fromJson(j);
  }
}
