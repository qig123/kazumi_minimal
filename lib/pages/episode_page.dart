import 'dart:io';

import 'package:flutter/material.dart';

import '../models/episode_item.dart';
import '../models/plugin_rule.dart';
import '../models/search_item.dart';
import '../services/anime_parser_service.dart';
import '../services/video_sniffer_service.dart';
import 'simple_player_page.dart';

class EpisodePage extends StatefulWidget {
  final PluginRule rule;
  final SearchItem item;

  const EpisodePage({
    super.key,
    required this.rule,
    required this.item,
  });

  @override
  State<EpisodePage> createState() => _EpisodePageState();
}

class _EpisodePageState extends State<EpisodePage>
    with SingleTickerProviderStateMixin {
  final _parser = AnimeParserService();
  final _sniffer = VideoSnifferService();

  bool _loading = false;
  String? _error;
  List<EpisodeItem> _episodes = [];
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadEpisodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final detailUrl =
        Uri.parse(widget.rule.baseUrl).resolve(widget.item.link).toString();

    final items = await _parser.parseChapters(widget.rule, detailUrl);

    if (!mounted) return;

    final maxRoad = items.isEmpty
        ? 0
        : items.map((e) => e.roadIndex).reduce((a, b) => a > b ? a : b);
    _tabController?.dispose();
    _tabController = TabController(
      length: maxRoad + 1,
      vsync: this,
    );

    setState(() {
      _episodes = items;
      _loading = false;
      if (items.isEmpty) {
        _error = 'No episodes found';
      }
    });
  }

  Map<String, String> _buildHeaders(String playPageUrl) {
    final origin = Uri.parse(playPageUrl).origin;
    final referer = origin.isEmpty ? playPageUrl : '$origin/';
    return {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'Referer': referer,
    };
  }

  Future<void> _sniffAndPlay(String playPageUrl) async {
    if (!Platform.isWindows) {
      setState(() => _error = 'Windows only');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Sniffing video source...'),
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 12),
            Expanded(child: Text('Please wait')),
          ],
        ),
      ),
    );

    try {
      final directUrl = await _sniffer.getDirectUrl(playPageUrl);
      if (!mounted) return;
      Navigator.of(context).pop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SimplePlayerPage(
            url: directUrl,
            headers: _buildHeaders(playPageUrl),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Sniff failed'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  List<EpisodeItem> _roadEpisodes(int roadIndex) {
    return _episodes.where((e) => e.roadIndex == roadIndex).toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxRoad = _episodes.isEmpty
        ? 0
        : _episodes.map((e) => e.roadIndex).reduce((a, b) => a > b ? a : b);
    final tabCount = maxRoad + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.name),
        bottom: tabCount > 0 && _tabController != null
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: List.generate(
                  tabCount,
                  (i) => Tab(text: '线路${i + 1}'),
                ),
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(tabCount, (i) {
                    final episodes = _roadEpisodes(i);
                    return ListView.builder(
                      itemCount: episodes.length,
                      itemBuilder: (_, index) {
                        final ep = episodes[index];
                        return ListTile(
                          title: Text(ep.title),
                          onTap: () => _sniffAndPlay(ep.url),
                        );
                      },
                    );
                  }),
                ),
    );
  }
}
