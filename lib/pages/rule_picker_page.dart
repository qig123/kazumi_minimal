import 'package:flutter/material.dart';
import '../models/rule_info.dart';

class RulePickerPage extends StatefulWidget {
  final List<RuleInfo> rules;
  final RuleInfo? selected;
  final Future<List<RuleInfo>> Function(bool includeOutdated) onRefresh;

  const RulePickerPage({
    super.key,
    required this.rules,
    required this.selected,
    required this.onRefresh,
  });

  @override
  State<RulePickerPage> createState() => _RulePickerPageState();
}

class _RulePickerPageState extends State<RulePickerPage> {
  late List<RuleInfo> _allRules;
  late List<RuleInfo> _rules;
  RuleInfo? _selected;
  bool _loading = false;
  bool _showOutdated = false;
  static const int _outdatedDays = 365;

  @override
  void initState() {
    super.initState();
    _allRules = widget.rules;
    _rules = _filterRules(_allRules, _showOutdated);
    _selected = widget.selected;
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final rules = await widget.onRefresh(true);
      setState(() {
        _allRules = rules;
        _rules = _filterRules(_allRules, _showOutdated);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch rules: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Rule'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading && _rules.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _rules.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No available rules'),
                      const SizedBox(height: 8),
                      const Text('Tap refresh to download rules'),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Show outdated rules'),
                          value: _showOutdated,
                          onChanged: (value) {
                            setState(() {
                              _showOutdated = value;
                              _rules = _filterRules(_allRules, _showOutdated);
                            });
                          },
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _rules.length,
                            itemBuilder: (_, i) {
                              final rule = _rules[i];
                              final selected = _selected?.name == rule.name;

                              final date =
                                  DateTime.fromMillisecondsSinceEpoch(rule.lastUpdate);
                              final m = date.month.toString().padLeft(2, '0');
                              final d = date.day.toString().padLeft(2, '0');
                              final dateStr = '${date.year}-$m-$d';

                              return ListTile(
                                title: Text(rule.name),
                                subtitle: Text('v${rule.version}  Updated: $dateStr'),
                                trailing: selected
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                onTap: () {
                                  setState(() => _selected = rule);
                                  Navigator.of(context).pop(rule);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                  ],
                ),
    );
  }

  List<RuleInfo> _filterRules(List<RuleInfo> rules, bool includeOutdated) {
    if (includeOutdated) return List<RuleInfo>.from(rules);
    final cutoff =
        DateTime.now().subtract(const Duration(days: _outdatedDays));
    return rules.where((rule) {
      if (rule.name.isEmpty) return false;
      if (rule.lastUpdate <= 0) return false;
      final last = DateTime.fromMillisecondsSinceEpoch(rule.lastUpdate);
      return last.isAfter(cutoff);
    }).toList();
  }
}
