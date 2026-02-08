import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plugin_rule.dart';
import '../models/search_item.dart';
import '../services/anime_parser_service.dart';
import '../services/video_sniffer_service.dart';
import 'simple_player_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _parser = AnimeParserService();
  final _sniffer = VideoSnifferService();

  List<SearchItem> _results = [];
  PluginRule? _rule;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRule();
  }

  Future<void> _loadRule() async {
    try {
      final jsonStr = await rootBundle.loadString('aowu.json');
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      _rule = PluginRule.fromJson(map);
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = 'Failed to load rule: $e');
    }
  }

  Future<void> _search() async {
    if (_rule == null) return;
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items =
          await _parser.search(_rule!, _controller.text.trim());
      setState(() => _results = items);
    } catch (e) {
      setState(() => _error = 'Search failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anime Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _search(),
                    decoration: const InputDecoration(
                      hintText: 'Enter keyword',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final item = _results[i];
                return ListTile(
                  title: Text(item.name),
                  onTap: () {
                    _sniffVideo(item.link);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
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

  Future<void> _sniffVideo(String link) async {
    if (!Platform.isWindows) {
      setState(() => _error = 'Windows only');
      return;
    }

    final playPageUrl =
        Uri.parse(_rule!.baseUrl).resolve(link).toString();

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
}
