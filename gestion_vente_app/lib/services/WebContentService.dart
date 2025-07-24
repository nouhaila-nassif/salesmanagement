import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;

class WebContentService {
  static Future<String> fetchContentFromDislogroup() async {
    try {
      final response = await http.get(Uri.parse("https://dislogroup.com"));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        final bodyText = document.body?.text ?? "";
        return bodyText;
      } else {
        return "Erreur lors du chargement du site : ${response.statusCode}";
      }
    } catch (e) {
      return "Erreur de récupération du site : $e";
    }
  }
}
