import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/article_model.dart';
import '../services/article_service.dart';
import '../widgets/article_diaglog.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late Future<List<Article>> _futureArticles;
  List<Article> _allArticles = [];
  List<Article> _filteredArticles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _futureArticles = getAllArticles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredArticles = _allArticles.where((article) {
        final titleLower = article.title.toLowerCase();
        return titleLower.contains(query);
      }).toList();
    });
  }

  Future<List<Article>> getAllArticles() async {
    final response = await ArticleService().getAllArticle();
    final articles = response.map((e) => Article.fromJson(e)).toList();
    _allArticles = articles;
    _filteredArticles = articles;
    return articles;
  }

  Widget _statusChip(bool active) {
    return Chip(
      label: Text(active ? 'Active' : 'Inactive'),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: active ? Colors.green : Colors.grey),
    );
  }

  Future<void> openAddArticleDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return ArticleDialogue(
          onSave: (payload, ctx) async {
            try {
              // Simulate a delay for 5 seconds to show loading animation
              await Future.delayed(const Duration(seconds: 5));

              final Map res = await ArticleService().createArticle(payload);
              final dynamic created = res['article'] ?? res['data'] ?? res;

              if (created is Map<String, dynamic>) {
                final newArticle = Article.fromJson(created);
                setState(() {
                  _allArticles.insert(0, newArticle);
                  _onSearchChanged();
                });
              } else {
                throw Exception("Unexpected create response: $res");
              }

              if (ctx.mounted) Navigator.of(ctx).pop();
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Article added.')));
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to add. $e')));
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openAddArticleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search articles by title...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                ),
              ),
            ),

            // Article list
            Expanded(
              child: FutureBuilder<List<Article>>(
                future: _futureArticles,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: CustomText(
                          text: 'No articles to display.',
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator.adaptive(strokeWidth: 3.sp),
                          SizedBox(height: 10.h),
                          CustomText(
                            text: 'Loading articles...',
                            fontSize: 14.sp,
                          ),
                        ],
                      ),
                    );
                  }

                  if (_filteredArticles.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: CustomText(
                          text: 'No articles match your search.',
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    itemCount: _filteredArticles.length,
                    separatorBuilder: (context, index) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final article = _filteredArticles[index];
                      final preview = article.content.isNotEmpty
                          ? article.content.first
                          : "";

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12.r),
                          onTap: () {
                            debugPrint('Tapped index $index: ${article.aid}');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DetailArticleScreen(article: article),
                              ),
                            ).then((updatedArticle) {
                              // Handle the updated article if returned
                              if (updatedArticle != null && updatedArticle is Article) {
                                setState(() {
                                  // Find and update the article in the lists
                                  final index = _allArticles.indexWhere((a) => a.aid == updatedArticle.aid);
                                  if (index != -1) {
                                    _allArticles[index] = updatedArticle;
                                    _onSearchChanged(); // Refresh filtered list
                                  }
                                });
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 15.w,
                              vertical: 15.h,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: CustomText(
                                              text: article.title.isEmpty
                                                  ? 'Untitled'
                                                  : article.title,
                                              fontSize: 24.sp,
                                              fontWeight: FontWeight.bold,
                                              maxLines: 2,
                                            ),
                                          ),
                                          _statusChip(article.isActive),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      CustomText(
                                        text: article.name,
                                        fontSize: 13.sp,
                                      ),
                                      if (preview.isNotEmpty) ...[
                                        SizedBox(height: 6.h),
                                        CustomText(
                                          text: preview,
                                          fontSize: 12.sp,
                                          maxLines: 2,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
