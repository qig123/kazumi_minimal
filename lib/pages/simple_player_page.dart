import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kazumi_minimal/utils/Utils.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class SimplePlayerPage extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  const SimplePlayerPage({
    super.key,
    required this.url,
    required this.headers,
  });

  @override
  State<SimplePlayerPage> createState() => _SimplePlayerPageState();
}

class _SimplePlayerPageState extends State<SimplePlayerPage> {
  late final Player _player;
  late final VideoController _videoController;

  @override
  void initState() {
    super.initState();
    _player = Player(
      configuration: const PlayerConfiguration(
        adBlocker: true,
        logLevel: MPVLogLevel.v,
      ),
    );
    _videoController = VideoController(_player);

    _player.stream.log.listen((event) {
      debugPrint('MPV LOG: [${event.level}] ${event.prefix}: ${event.text}');
    });

    _initAndPlay();
  }

  Future<void> _initAndPlay() async {
    await _setDemuxerCacheDir();

    debugPrint('Player open url: ${widget.url}');
    debugPrint('Player headers: ${widget.headers}');

    _player.open(
      Media(widget.url, httpHeaders: widget.headers),
      play: true,
    );
  }

  Future<void> _setDemuxerCacheDir() async {
    try {
      final platform = _player.platform;
      if (platform is! NativePlayer) return;

      final cacheDir = Utils.getPlayerTempPath();
      await platform.setProperty('demuxer-cache-dir', await cacheDir);
      // await platform.setProperty('cache', 'yes');
      // await platform.setProperty('demuxer-max-bytes', '524288000');
      // await platform.setProperty('demuxer-readahead-secs', '120');
      // await platform.setProperty('demuxer-max-back-bytes', '104857600');
      // await platform.setProperty('hls-bitrate', 'max');
      // await platform.setProperty('stream-buffer-size', '10485760');
      debugPrint('Set demuxer-cache-dir: $cacheDir');
    } catch (e) {
      debugPrint('Failed to set demuxer-cache-dir: $e');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          const SizedBox.expand(),
          SizedBox.expand(
            child: Video(
              controller: _videoController,
              fit: BoxFit.contain,
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
