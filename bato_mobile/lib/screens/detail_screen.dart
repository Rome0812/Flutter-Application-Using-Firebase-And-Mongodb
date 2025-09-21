import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/article_model.dart';
import '../widgets/custom_text.dart';
import '../utils/loading.dart';

class DetailArticleScreen extends StatefulWidget {
  final Article article;

  const DetailArticleScreen({super.key, required this.article});

  @override
  State<DetailArticleScreen> createState() => _DetailArticleScreenState();
}

class _DetailArticleScreenState extends State<DetailArticleScreen> {
  late Article currentArticle;
  late TextEditingController titleController;
  late TextEditingController nameController;
  late TextEditingController contentController;
  late bool isActive;
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();

    currentArticle = widget.article;

    titleController = TextEditingController(text: currentArticle.title);
    nameController = TextEditingController(text: currentArticle.name);
    contentController = TextEditingController(
      text: currentArticle.content.join("\n"),
    );
    isActive = currentArticle.isActive;
  }

  @override
  void dispose() {
    titleController.dispose();
    nameController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void saveChanges() async {

    LoadingOverlay.show(context, message: "Uploading article..."); 
    await Future.delayed(const Duration(seconds: 2));

    final updatedArticle = Article(
      aid: currentArticle.aid,
      name: nameController.text,
      title: titleController.text,
      content: contentController.text
          .split(RegExp(r'[\n,]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      isActive: isActive,
    );

    setState(() {
      currentArticle = updatedArticle;
      isEditMode = false;
    });

    // hide loading
    LoadingOverlay.hide(context);

    // return to parent if needed
    Navigator.pop(context, updatedArticle);
  }

  void toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: widget.article.title.isEmpty
              ? "New Article"
              : widget.article.title,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.close : Icons.edit),
            onPressed: toggleEditMode,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: SingleChildScrollView(
          child: isEditMode ? _buildEditMode() : _buildViewMode(),
        ),
      ),
    );
  }

  // ------------------ VIEW MODE ------------------
  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image placeholder
        Container(
          height: 180.h,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16.h),

        // Title + Active badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text: titleController.text,
              fontSize: 25.sp,
              fontWeight: FontWeight.bold,
            ),
            if (isActive)
              Chip(
                label: const Text('Active'),
                visualDensity: VisualDensity.compact,
                side: const BorderSide(color: Colors.green),
              ),
          ],
        ),
        SizedBox(height: 8.h),

        // Author / Name
        Text(
          nameController.text,
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15.h),

        // Content as bullet points
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: contentController.text
              .split(RegExp(r'[\n,]+'))
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• "),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // ------------------ EDIT MODE ------------------
  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image placeholder
        Container(
          height: 180.h,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: const Center(
            child: Icon(Icons.image, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16.h),

        // Title field
        TextField(
          controller: titleController,
          decoration: _inputDecoration("Title"),
        ),
        SizedBox(height: 12.h),

        // Author / Name field
        TextField(
          controller: nameController,
          decoration: _inputDecoration("Author / Name"),
        ),
        SizedBox(height: 12.h),

        // Content field
        TextField(
          controller: contentController,
          minLines: 4,
          maxLines: null,
          decoration: _inputDecoration(
            "Content (one item per line or comma-separated)",
          ),
        ),
        SizedBox(height: 12.h),
        Padding(padding: EdgeInsets.symmetric(vertical: 11.h)),

        // Active toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              text: "Active",
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            Switch(
              value: isActive,
              activeTrackColor: Colors.green,
              onChanged: (val) {
                setState(() {
                  isActive = val;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Save button (purple pill)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: saveChanges,
            icon: const Icon(Icons.save, color: Colors.deepPurple),
            label: const Text("Save Changes"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r), // pill shape
              ),
            ),
          ),
        ),
        SizedBox(height: 7.h),

        // Cancel button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: toggleEditMode,
            icon: const Icon(Icons.cancel, color: Colors.deepPurple),
            label: const Text("Cancel"),
             style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.deepPurple,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r), // pill shape
              ),
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Tip
        CustomText(
          text:
              "Tip: Separate multiple content items using new lines or commas.",
          fontSize: 12.sp,
          color: Colors.black,
        ),
      ],
    );
  }
}
