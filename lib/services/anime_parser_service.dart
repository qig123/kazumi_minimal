import 'package:dio/dio.dart';
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

import '../models/plugin_rule.dart';
import 'package:flutter/foundation.dart';

import '../models/episode_item.dart';
import '../models/search_item.dart';

class AnimeParserService {
  final bool debug;
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

  AnimeParserService({this.debug = kDebugMode});

  Future<List<SearchItem>> search(
      PluginRule rule, String keyword) async {
    final url =
    rule.searchURL.replaceAll('@keyword', Uri.encodeComponent(keyword));

    if (debug) {
      debugPrint('search: url=$url rule=${rule.name}');
      debugPrint('search: xpath list=${rule.searchList}');
      debugPrint('search: xpath name=${rule.searchName}');
      debugPrint('search: xpath link=${rule.searchResult}');
    }

    final response = await _dio.get(url);

    final html = response.data?.toString() ?? '';
    final xpath = HtmlXPath.html(html);

    final listNodes = xpath.query(rule.searchList);

    final List<SearchItem> results = [];

    if (debug) {
      debugPrint(
        'search: status=${response.statusCode} htmlLength=${html.length} listNodes=${listNodes.nodes.length}',
      );
    }

    for (final node in listNodes.nodes) {
      final itemXpath = HtmlXPath(node);

      final nameNodes = itemXpath.query(rule.searchName).nodes;
      final linkNodes = itemXpath.query(rule.searchResult).nodes;

      if (nameNodes.isEmpty || linkNodes.isEmpty) {
        if (debug) {
          debugPrint(
            'search: skip item, nameNodes=${nameNodes.length} linkNodes=${linkNodes.length}',
          );
        }
        continue;
      }

      final nameNode = nameNodes.first;
      final linkNode = linkNodes.first;

      final name = (nameNode.text ?? '').trim();
      final link = linkNode.attributes['href'] ?? '';

      if (name.isEmpty || link.isEmpty) continue;

      results.add(SearchItem(name: name, link: link));

      if (debug && results.length <= 3) {
        debugPrint('search: item=${results.length} name="$name" link="$link"');
      }
    }

    if (debug) {
      debugPrint('search: total=${results.length}');
    }

    return results;
  }

  Future<List<EpisodeItem>> parseChapters(
    PluginRule rule,
    String detailUrl,
  ) async {
    try {
      if (debug) {
        debugPrint('parseChapters: url=$detailUrl rule=${rule.name}');
        debugPrint('parseChapters: xpath roads=${rule.chapterRoads}');
        debugPrint('parseChapters: xpath items=${rule.chapterResult}');
      }

      final response = await _dio.get(detailUrl);
      final html = response.data?.toString() ?? '';
      final xpath = HtmlXPath.html(html);
      final roadNodes = xpath.query(rule.chapterRoads).nodes;
      final List<EpisodeItem> results = [];

      if (debug) {
        debugPrint(
          'parseChapters: status=${response.statusCode} htmlLength=${html.length} roads=${roadNodes.length}',
        );
      }

      for (var i = 0; i < roadNodes.length; i++) {
        final roadNode = roadNodes[i];
        final roadXpath = HtmlXPath(roadNode);
        final itemNodes = roadXpath.query(rule.chapterResult).nodes;

        if (debug) {
          debugPrint('parseChapters: road=$i items=${itemNodes.length}');
        }

        for (final node in itemNodes) {
          try {
            final title = (node.text ?? '').trim();
            final href = node.attributes['href'] ?? '';
            if (title.isEmpty || href.isEmpty) continue;
            if (href.startsWith('javascript:') || href == '#') continue;

            final url = Uri.parse(rule.baseUrl).resolve(href).toString();
            results.add(EpisodeItem(
              title: title,
              url: url,
              roadIndex: i,
            ));

            if (debug && results.length <= 3) {
              debugPrint(
                'parseChapters: item=${results.length} title="$title" url="$url" road=$i',
              );
            }
          } catch (e) {
            if (debug) {
              debugPrint('parseChapters: skip item due to error: $e');
            }
            continue;
          }
        }
      }

      debugPrint(
        'parseChapters: ${results.length} items from $detailUrl',
      );
      return results;
    } catch (e) {
      debugPrint('parseChapters error: $e');
      return [];
    }
  }
}
