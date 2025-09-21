import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart';

class ArticleService {
  List listData = [];

  Future<List> getAllArticle() async {
    final url = '$host/api/articles'; 
    print('Fetching articles from $url');

    Response response = await get(Uri.parse(url));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('Decoded data: $data');
      return data is List ? data : data['articles'] ?? [];
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  Future<Map> createArticle(dynamic article) async {
    final response = await post(
      Uri.parse('$host/api/articles'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to create article: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<Map> updateArticle(String id, dynamic article) async {
    final response = await put(
      Uri.parse('$host/api/articles/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(article),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to update article: ${response.statusCode} ${response.body}',
      );
    }
  }
}
