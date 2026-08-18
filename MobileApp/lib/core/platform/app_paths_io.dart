import 'package:path_provider/path_provider.dart';

Future<String?> appDocumentsPath() async {
  final dir = await getApplicationDocumentsDirectory();
  return dir.path;
}

Future<String?> appTemporaryPath() async {
  final dir = await getTemporaryDirectory();
  return dir.path;
}
