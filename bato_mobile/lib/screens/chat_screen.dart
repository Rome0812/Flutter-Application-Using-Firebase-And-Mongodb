import 'package:bato_advmobprog/screens/chat_detailscreen.dart';
import 'package:bato_advmobprog/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    final userData = await userService.value.getUserData();
    setState(() {
      _currentUserEmail = userData['email'];
    });
    
    // Sync current user to Firestore for chat functionality
    await userService.value.syncCurrentUserToFirestore();
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 23.w),
            child: TextField(
              controller: _searchChatController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_searchChatController.text.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Clear',
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          setState(() {
                            _searchChatController.clear();
                            searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                
              ),
            ),
          ),
          SizedBox(height: 10.h),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Center(
                    child: CustomText(
                      text: 'Error loading users',
                      fontSize: 16.sp,
                    ),
                  ),
                );
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final users = snapshot.data!;
                final filteredUsers = users
                    .where((user) {
                      // Exclude current user from the list
                      if (_currentUserEmail != null && 
                          user['email']?.toString() == _currentUserEmail) {
                        return false;
                      }
                      
                      // Apply search filter
                      return user['firstName']
                          .toString()
                          .toLowerCase()
                          .contains(searchText.toLowerCase()) ||
                      user['email']
                          .toString()
                          .toLowerCase()
                          .contains(searchText.toLowerCase());
                    })
                    .toList();

                if (filteredUsers.isEmpty) {
                  return Container(
                    height: ScreenUtil().screenHeight * 0.6,
                    padding: EdgeInsets.all(16.sp),
                    child: Center(
                      child: CustomText(
                        text: 'No users found',
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail!,
                              tappedUser: user,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: CustomText(
                              text: user['firstName'] != null &&
                                      user['firstName'].toString().isNotEmpty
                                  ? user['firstName'][0].toUpperCase()
                                  : 'U',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          title: CustomText(
                            text: user['firstName'] ?? 'Unknown',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: CustomText(
                            text: user['email'] ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }

              return Container(
                height: ScreenUtil().screenHeight * 0.6,
                padding: EdgeInsets.all(16.sp),
                child: Center(
                  child: CustomText(
                    text: 'No users found',
                    fontSize: 16.sp,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
