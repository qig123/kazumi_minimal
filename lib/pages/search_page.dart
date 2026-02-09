import 'package:flutter/material.dart';
import '../models/plugin_rule.dart';
import '../models/rule_info.dart';
import '../models/search_item.dart';
import '../services/anime_parser_service.dart';
import 'package:kazumi_minimal/services/rule_repository.dart';
import 'package:kazumi_minimal/pages/episode_page.dart';
import 'package:kazumi_minimal/pages/rule_picker_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _parser = AnimeParserService();
  final _repo = RuleRepository();

  List<SearchItem> _results = [];
  PluginRule? _rule;
  RuleInfo? _selectedRule;
  List<RuleInfo> _rules = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      debugPrint('SearchPage: loading rules from cache');
      final rules = await _repo.loadIndexFromCache();
      if (rules.isEmpty) {
        debugPrint('SearchPage: no cached rules available');
        setState(() => _error = 'No rules. Tap Rules to refresh.');
        return;
      }
      _rules = rules;
      _selectedRule = rules.first;
      _rule = await _repo.loadRule(_selectedRule!.name);
      setState(() => _error = null);
    } catch (e) {
      setState(() => _error = 'Failed to load rules: $e');
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
      appBar: AppBar(
        title: Text(
          _selectedRule == null
              ? 'Anime Search'
              : 'Anime Search (${_selectedRule!.name})',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openRulePicker,
            tooltip: 'Rules',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedRule == null)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text('Please select a rule to search'),
            ),
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
                  onPressed: _rule == null ? null : _search,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EpisodePage(
                          rule: _rule!,
                          item: item,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Future<void> _openRulePicker() async {
    final picked = await Navigator.of(context).push<RuleInfo>(
      MaterialPageRoute(
        builder: (_) => RulePickerPage(
          rules: _rules,
          selected: _selectedRule,
          onRefresh: _refreshRules,
        ),
      ),
    );
    if (picked == null) return;
    await _selectRule(picked);
  }

  Future<List<RuleInfo>> _refreshRules(bool includeOutdated) async {
    debugPrint('SearchPage: refreshing rules from remote');
    final rules = await _repo.refreshIndex(includeOutdated: true);
    setState(() => _rules = rules);
    return rules;
  }

  Future<void> _selectRule(RuleInfo rule) async {
    try {
      debugPrint('SearchPage: selecting rule ${rule.name}');
      final loaded = await _repo.loadRule(rule.name);
      setState(() {
        _selectedRule = rule;
        _rule = loaded;
        _results = [];
        _error = null;
      });
    } catch (e) {
      setState(() =>
          _error = 'Failed to load rule: $e. Tap Rules to refresh.');
    }
  }
}
