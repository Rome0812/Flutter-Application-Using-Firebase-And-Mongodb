class Article {
  final String aid;
  final String name;
  final String title;
  final List<String> content;
  final bool isActive;
 
  Article({
    required this.aid,
    required this.name,
    required this.title,
    required this.content,
    required this.isActive,
  });
 
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      aid: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content'] != null
          ? List<String>.from(json['content'].map((e) => e.toString()))
          : <String>[],
      isActive: json['isActive'] == true,
    );
  }
    String get body => content.join("\n\n");
    
}
