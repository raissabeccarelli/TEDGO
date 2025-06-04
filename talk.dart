class Talk {
  final String title;
  final String speakers;
  final String description;
  final String url;
  final String schedule_time;

  Talk.fromJSON(Map<String, dynamic> jsonMap) //metodo fromJSON che si aspetta una mappa, json, 
  //formata da chiave e valore, dove la chiave è una stringa e il valore è dinamico
      : title = jsonMap['title'],
        speakers = (jsonMap['speakers'] ?? ""), //se quell'attributo non è presente, viene di default messo blank
        url = (jsonMap['url'] ?? ""),
        description = (jsonMap['description'] ?? ""),
        schedule_time = (jsonMap['schedule_time']);
}//il metodo torna un oggetto istanziato di tipo Talk
