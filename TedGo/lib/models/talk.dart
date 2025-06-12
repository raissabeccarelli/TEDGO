class Talk {
  final String id;
  final String title;
  final String speakers;
  final String description;
  final String url;
  final String schedule_time;

  /*Talk({
    required this.id,
    required this.title,
    this.speakers = '',
    this.description = '',
    this.url = '',
    this.schedule_time = '',
  });*/

  Talk.fromJSON(Map<String, dynamic> jsonMap) //metodo fromJSON che si aspetta una mappa, json,
    //formata da chiave e valore, dove la chiave è una stringa e il valore è dinamico
    : id = jsonMap['id'],
      title = jsonMap['title'],
      speakers = (jsonMap['speakers'] ?? ""), //se quell'attributo non è presente, viene di default messo blank
      url = (jsonMap['url'] ?? ""),
      description = (jsonMap['description'] ?? ""),
      schedule_time = (jsonMap['schedule_time']);
} //il metodo torna un oggetto istanziato di tipo Talk

extension TalkExtension on Talk {
  String get embedUrl {
    if (url.contains("ted.com/talks/")) {
      return url.replaceFirst("https://www.ted.com/talks/", "https://embed.ted.com/talks/");
    }
    return url; // fallback: usa url originale
  }
}

class WatchNextTalk {
  final String id;
  final String title;
  final String url;

  WatchNextTalk.fromJSON(Map<String, dynamic> jsonMap)
    : id = jsonMap['_id'],
      title = jsonMap['title'],
      url = jsonMap['url'];
}

extension WatchNextTalkExtension on WatchNextTalk {
  String get embedUrl {
    if (url.contains("ted.com/talks/")) {
      return url.replaceFirst("https://www.ted.com/talks/", "https://embed.ted.com/talks/");
    }
    return url;
  }
}
