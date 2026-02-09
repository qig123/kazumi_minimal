import 'package:path_provider/path_provider.dart';

class Utils {
  static Future<String> getPlayerTempPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }
}