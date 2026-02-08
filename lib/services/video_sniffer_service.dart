import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';

class VideoSnifferService {
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  HeadlessWebview? _webview;
  final List<StreamSubscription> _subs = [];

  Future<String> getDirectUrl(String playPageUrl) async {
    final version = await HeadlessWebview.getWebViewVersion();
    if (version == null) {
      throw StateError('WebView2 Runtime not found');
    }

    _webview ??= HeadlessWebview();
    await _webview!.run();
    await _webview!.setUserAgent(_ua);

    final completer = Completer<String>();
    bool done = false;

    bool isM3u8(String url, String? contentType) {
      final lower = url.toLowerCase();
      final ct = (contentType ?? '').toLowerCase();
      return lower.contains('.m3u8') ||
          ct.contains('application/vnd.apple.mpegurl') ||
          ct.contains('application/x-mpegurl');
    }

    bool isMp4(String url, String? contentType) {
      final lower = url.toLowerCase();
      final ct = (contentType ?? '').toLowerCase();
      return lower.contains('.mp4') || ct.contains('video/mp4');
    }

    void completeWith(String url) {
      if (done) return;
      done = true;
      debugPrint('Sniffed video url: $url');
      if (!completer.isCompleted) {
        completer.complete(url);
      }
    }

    await _unload();

    _subs.add(_webview!.onM3USourceLoaded.listen((data) {
      final url = data['url'] ?? '';
      if (url.isNotEmpty && isM3u8(url, 'application/vnd.apple.mpegurl')) {
        completeWith(url);
      }
    }));
    _subs.add(_webview!.onVideoSourceLoaded.listen((data) {
      final url = data['url'] ?? '';
      final contentType = data['contentType'];
      if (url.isNotEmpty && (isMp4(url, contentType) || isM3u8(url, contentType))) {
        completeWith(url);
      }
    }));

    await _loadWithReferer(playPageUrl);

    try {
      final url = await completer.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw TimeoutException('Timed out after 20s'),
      );
      await _unload();
      return url;
    } catch (_) {
      await _unload();
      rethrow;
    }
  }

  Future<void> _loadWithReferer(String playPageUrl) async {
    final origin = Uri.parse(playPageUrl).origin;
    if (origin.isEmpty) {
      await _webview!.loadUrl(playPageUrl);
      return;
    }

    await _webview!.loadUrl(origin);
    final script = 'window.location.href = ${jsonEncode(playPageUrl)};';
    await _webview!.executeScript(script);
  }

  Future<void> _unload() async {
    for (final sub in _subs) {
      try {
        await sub.cancel();
      } catch (_) {}
    }
    _subs.clear();

    if (_webview == null) return;
    try {
      await _webview!.executeScript(
        "window.location.href = 'about:blank';",
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _unload();
    await _webview?.dispose();
    _webview = null;
  }
}
