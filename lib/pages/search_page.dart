import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/plugin_rule.dart';
import '../models/search_item.dart';
import '../services/anime_parser_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _parser = AnimeParserService();

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
                    final fullUrl = Uri.parse(_rule!.baseUrl)
                        .resolve(item.link)
                        .toString();
                    debugPrint(fullUrl);
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}