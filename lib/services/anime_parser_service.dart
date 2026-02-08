import 'package:dio/dio.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import '../models/plugin_rule.dart';
import '../models/search_item.dart';

class AnimeParserService {
  final Dio _dio = Dio(
    BaseOptions(
      headers: {
        'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  Future<List<SearchItem>> search(
      PluginRule rule, String keyword) async {
    final url =
    rule.searchURL.replaceAll('@keyword', Uri.encodeComponent(keyword));

    final response = await _dio.get(url);

    final xpath = HtmlXPath.html(response.data);

    final listNodes = xpath.query(rule.searchList);

    final List<SearchItem> results = [];

    for (final node in listNodes.nodes) {
      final itemXpath = HtmlXPath(node);

      final nameNodes = itemXpath.query(rule.searchName).nodes;
      final linkNodes = itemXpath.query(rule.searchResult).nodes;

      if (nameNodes.isEmpty || linkNodes.isEmpty) {
        continue;
      }

      final nameNode = nameNodes.first;
      final linkNode = linkNodes.first;

      final name = (nameNode.text ?? '').trim();
      final link = linkNode.attributes['href'] ?? '';

      if (name.isEmpty || link.isEmpty) continue;

      results.add(SearchItem(name: name, link: link));
    }

    return results;
  }
}
