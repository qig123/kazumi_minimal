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
    return rules;
  }

  Future<PluginRule> loadRule(String name) async {
    try {
      debugPrint('RuleRepository: loading rule from GitHub: $name');
      final response = await http
          .get(Uri.parse('$baseUrl/$name.json'))
          .timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('Rule file not found: $name.json');
      }

      final content = utf8.decode(response.bodyBytes);
      final jsonMap = json.decode(content) as Map<String, dynamic>;
      debugPrint('RuleRepository: loaded rule from GitHub: $name');
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

  String _cachePath() {
    final appData = Platform.environment['APPDATA'];
    if (appData != null && appData.isNotEmpty) {
      return '$appData\\kazumi_minimal\\$cacheFileName';
    }
    return '${Directory.systemTemp.path}\\$cacheFileName';
  }
}
