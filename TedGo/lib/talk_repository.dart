import 'package:http/http.dart' as http;
import 'dart:convert';
import 'models/talk.dart';

Future<List<Talk>> initEmptyList() async {
  Iterable list = json.decode("[]");
  return list.map((model) => Talk.fromJSON(model)).toList();
}

Future<List<Talk>> get_Talks_By_Channel(String channel, int page) async {
  var url = 'https://pk135uzjb1.execute-api.us-east-1.amazonaws.com/default/Get_Talks_By_Channel';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'_id': channel}),
  );

  if (response.statusCode == 200) {
    final body = utf8.decode(response.bodyBytes);
    print("Response body from channel API: $body");

    final Map<String, dynamic> jsonMap = json.decode(body);
    final List<dynamic> talksList = jsonMap["talks"];

    return talksList.map((json) => Talk.fromJSON(json)).toList();
  } else {
    throw Exception('Failed to load talks. Status code: ${response.statusCode}');
  }
}

Future<List<WatchNextTalk>> get_WatchNext_By_ID(String talkId) async {
  var url = 'https://lpgx6rnx6i.execute-api.us-east-1.amazonaws.com/default/Get_WatchNext_By_ID';

  final response = await http.post(
    Uri.parse(url),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'_id': talkId}),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> responseMap = json.decode(response.body);

    // Estrapolo la lista dentro 'watch_next'
    final List<dynamic> watchNextList = responseMap['watch_next'];

    // Mappo la lista in oggetti WatchNextTalk
    return watchNextList.map((item) => WatchNextTalk.fromJSON(item)).toList();
  } else {
    throw Exception('Failed to load watch next talks');
  }
}
