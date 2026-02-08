import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/plugin_rule.dart';
import '../models/rule_info.dart';

class RuleRepository {
  // GitHub Raw ������ַ
  static const String baseUrl = 'https://raw.githubusercontent.com/Predidit/KazumiRules/master';
  static const String indexFile = 'index.json';
  static const int outdatedDays = 365;
  static const Duration requestTimeout = Duration(seconds: 10);
  static const String cacheFileName = 'rules_cache.json';

  Future<List<RuleInfo>> loadIndexFromCache(
      {bool includeOutdated = false}) async {
    final cache = await _loadCache();
    if (cache == null) {
      debugPrint('RuleRepository: cache miss at ${_cachePath()}');
      return [];
    }

    final list = json.decode(cache) as List<dynamic>;
    final rules = list
        .map((e) => RuleInfo.fromJson(e as Map<String, dynamic>))
        .where((r) => includeOutdated ? r.name.isNotEmpty : _isActive(r))
        .toList()
      ..sort(_sortRules);

    debugPrint('RuleRepository: loaded rules from cache: ${rules.length}');
    return rules;
  }

  Future<List<RuleInfo>> refreshIndex({bool includeOutdated = false}) async {
    final response = await http
        .get(Uri.parse('$baseUrl/$indexFile'))
        .timeout(requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load index: ${response.statusCode}');
    }

    final content = utf8.decode(response.bodyBytes);
    final list = json.decode(content) as List<dynamic>;

    final rules = list
        .map((e) => RuleInfo.fromJson(e as Map<String, dynamic>))
        .where((r) => includeOutdated ? r.name.isNotEmpty : _isActive(r))
        .toList()
      ..sort(_sortRules);

    await _saveCache(content);
    debugPrint('RuleRepository: refreshed rules from GitHub: ${rules.length}');
    await _refreshRuleFiles(rules);
    return rules;
  }

  Future<PluginRule> loadRule(String name) async {
    try {
      final content = await _loadRuleCache(name);
      if (content == null) {
        throw Exception('Rule not cached: $name');
      }
      final jsonMap = json.decode(content) as Map<String, dynamic>;
      debugPrint('RuleRepository: loaded rule from cache: $name');
      return PluginRule.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading rule $name: $e');
      rethrow;
    }
  }

  bool _isActive(RuleInfo rule) {
    if (rule.name.isEmpty) return false;
    if (rule.lastUpdate <= 0) return false;
    final cutoff = DateTime.now().subtract(const Duration(days: outdatedDays));
    final last = DateTime.fromMillisecondsSinceEpoch(rule.lastUpdate);
    return last.isAfter(cutoff);
  }

  int _sortRules(RuleInfo a, RuleInfo b) {
    final byUpdate = b.lastUpdate.compareTo(a.lastUpdate);
    if (byUpdate != 0) return byUpdate;
    return a.name.compareTo(b.name);
  }

  Future<String?> _loadCache() async {
    try {
      final file = File(_cachePath());
      if (!await file.exists()) return null;
      debugPrint('RuleRepository: reading cache ${file.path}');
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCache(String content) async {
    try {
      final file = File(_cachePath());
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      debugPrint('RuleRepository: saved cache ${file.path}');
    } catch (_) {}
  }

  Future<void> _refreshRuleFiles(List<RuleInfo> rules) async {
    for (final rule in rules) {
      if (rule.name.isEmpty) continue;
      try {
        debugPrint('RuleRepository: downloading rule ${rule.name}');
        final response = await http
            .get(Uri.parse('$baseUrl/${rule.name}.json'))
            .timeout(requestTimeout);
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        final content = utf8.decode(response.bodyBytes);
        await _saveRuleCache(rule.name, content);
      } catch (e) {
        debugPrint('RuleRepository: failed to download rule ${rule.name}: $e');
      }
    }
  }

  Future<String?> _loadRuleCache(String name) async {
    try {
      final file = File(_ruleCachePath(name));
      if (!await file.exists()) return null;
      debugPrint('RuleRepository: reading rule cache ${file.path}');
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveRuleCache(String name, String content) async {
    try {
      final file = File(_ruleCachePath(name));
      await file.parent.create(recursive: true);
      await file.writeAsString(content);
      debugPrint('RuleRepository: saved rule cache ${file.path}');
    } catch (_) {}
  }

  String _cachePath() {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\kazumi_minimal\\$cacheFileName';
    }
    return '${Directory.systemTemp.path}\\$cacheFileName';
  }

  String _ruleCachePath(String name) {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\kazumi_minimal\\rules\\$name.json';
    }
    return '${Directory.systemTemp.path}\\kazumi_minimal\\rules\\$name.json';
  }
}
