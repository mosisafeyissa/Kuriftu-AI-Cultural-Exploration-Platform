import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.get(Uri.parse('https://kuriftu-ai-cultural-exploration-platform-b7jj.onrender.com/api/artifacts/featured/'));
  print(response.statusCode);
  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    print(data.length);
  }
}
