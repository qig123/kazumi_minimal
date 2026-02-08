class PluginRule {
  final String name;
  final String baseUrl;
  final String searchURL;
  final String searchList;
  final String searchName;
  final String searchResult;
  final String chapterRoads;
  final String chapterResult;

  PluginRule({
    required this.name,
    required this.baseUrl,
    required this.searchURL,
    required this.searchList,
    required this.searchName,
    required this.searchResult,
    required this.chapterRoads,
    required this.chapterResult,
  });

  factory PluginRule.fromJson(Map<String, dynamic> json) {
    final baseUrl = (json['baseURL'] ?? json['baseUrl']) as String?;
    return PluginRule(
      name: (json['name'] ?? '') as String,
      baseUrl: baseUrl ?? '',
      searchURL: (json['searchURL'] ?? '') as String,
      searchList: (json['searchList'] ?? '') as String,
      searchName: (json['searchName'] ?? '') as String,
      searchResult: (json['searchResult'] ?? '') as String,
      chapterRoads: (json['chapterRoads'] ?? '') as String,
      chapterResult: (json['chapterResult'] ?? '') as String,
    );
  }
}
