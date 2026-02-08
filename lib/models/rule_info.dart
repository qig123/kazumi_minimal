class RuleInfo {
  final String name;
  final String version;
  final String author;
  final int lastUpdate;
  final bool useNativePlayer;

  const RuleInfo({
    required this.name,
    required this.version,
    required this.author,
    required this.lastUpdate,
    required this.useNativePlayer,
  });

  factory RuleInfo.fromJson(Map<String, dynamic> json) {
    return RuleInfo(
      name: (json['name'] ?? '') as String,
      version: (json['version'] ?? '') as String,
      author: (json['author'] ?? '') as String,
      lastUpdate: (json['lastUpdate'] ?? 0) as int,
      useNativePlayer: (json['useNativePlayer'] ?? false) as bool,
    );
  }
}
