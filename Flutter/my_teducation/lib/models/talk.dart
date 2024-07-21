class Talk {
  final String id;
  final String title;
  final String details;
  final String mainSpeaker;
  final String url;
  final String views;
  final String imageurl;
  final List watchnext;



  Talk.fromJSON(Map<String, dynamic> jsonMap) :
    id = jsonMap['internalId'],
    title = jsonMap['title'],
    details = jsonMap['description'],
    mainSpeaker = (jsonMap['speakers'] ?? ""),
    url = (jsonMap['url'] ?? ""),
    views = (jsonMap['views'] ?? "0"),
    imageurl = (jsonMap['image_url'] ?? ""),
    watchnext = (jsonMap['watch_next'] ?? "");
}