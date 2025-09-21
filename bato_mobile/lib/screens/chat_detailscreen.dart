import 'package:bato_advmobprog/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/custom_text.dart';
import '../services/user_service.dart';

final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> 
    with TickerProviderStateMixin {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  bool _isTyping = false;
  static const _postSendDelay = Duration(milliseconds: 600);
  
  // Animation controllers
  late AnimationController _messageAnimationController;
  late AnimationController _typingAnimationController;
  late AnimationController _sendButtonAnimationController;
  
  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _typingAnimation;
  late Animation<double> _sendButtonScaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
    
    // Initialize message animations
    _messageAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _messageAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Initialize typing animation
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize send button animation
    _sendButtonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _sendButtonScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _sendButtonAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _messageAnimationController.forward();
  }

  Future<String> _getCurrentUserId() async {
    try {
      final userData = await userService.value.getUserData();
      final uid = (userData['uid'] ?? '').toString();
      
      if (uid.isEmpty) {
        print('Warning: User UID is empty. UserData: $userData');
        final firebaseUser = userService.value.currentUser;
        if (firebaseUser != null) {
          print('Using Firebase Auth UID as fallback: ${firebaseUser.uid}');
          return firebaseUser.uid;
        }
        throw Exception('No user ID found in local storage or Firebase Auth');
      }
      
      return uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    _messageAnimationController.dispose();
    _typingAnimationController.dispose();
    _sendButtonAnimationController.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    // Animate send button
    _sendButtonAnimationController.forward().then((_) {
      _sendButtonAnimationController.reverse();
    });

    setState(() {
      _isSending = true;
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();
    
    print('💬 Chat Detail Screen:');
    print('  Tapped User ID: $tappedUserId');
    print('  Tapped User Name: $tappedUserName');

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60.w,
                    height: 60.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Loading chat...',
                    fontSize: 16.sp,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ],
              ),
            ),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return _buildErrorScreen(snap);
        }

        final currentUserId = snap.data!;
        print('👤 Current User ID: $currentUserId');
        
        chatService.debugListChatRooms();

          return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: _buildModernAppBar(context, tappedUserName),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFFFFFFF),
                      ],
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: chatService.getMessages(currentUserId, tappedUserId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildLoadingState(context);
                      }

                      if (snapshot.hasError) {
                        return _buildErrorState(context, snapshot.error.toString());
                      }

                      List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView.builder(
                        controller: _scrollCtrl,
                        reverse: true,
                        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                        itemCount: docs.length + (_isSending && _msgCtrl.text.trim().isNotEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isSending && _msgCtrl.text.trim().isNotEmpty && index == 0) {
                            return _buildSendingMessage(context, currentUserId);
                          }
                          
                          final messageIndex = (_isSending && _msgCtrl.text.trim().isNotEmpty) ? index - 1 : index;
                          final data = docs[messageIndex].data() as Map<String, dynamic>;
                          final msgText = (data['message'] ?? '').toString();
                          final senderId = (data['senderId'] ?? '').toString();
                          final timestamp = data['timestamp'] as Timestamp?;
                          final isMe = senderId == currentUserId;
                          
                          return _buildAnimatedMessage(
                            context,
                            msgText,
                            isMe,
                            timestamp,
                            messageIndex,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Typing indicator
              if (_isTyping) _buildTypingIndicator(context),

              // Modern Message Input Field
              _buildModernInputField(context, currentUserId, tappedUserId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorScreen(AsyncSnapshot<String> snap) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
            appBar: AppBar(
              elevation: 0,
              centerTitle: true,
        backgroundColor: const Color(0xFFF8FAFC),
        foregroundColor: const Color(0xFF1E293B),
              title: CustomText(
                text: 'Chat',
                fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFEE2E2),
                    Color(0xFFFEF2F2),
                  ],
                ),
                    ),
                    child: Icon(
                      Icons.person_off,
                      size: 40.sp,
                color: const Color(0xFFEF4444),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  CustomText(
                    text: 'Unable to load user data',
                    fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFDC2626),
                  ),
                  SizedBox(height: 8.h),
                  CustomText(
                    text: snap.hasError ? 'Error: ${snap.error}' : 'Please login again',
                    fontSize: 14.sp,
              color: const Color(0xFF64748B),
                    textAlign: TextAlign.center,
              fontWeight: FontWeight.w500,
                  ),
                  SizedBox(height: 24.h),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    child: CustomText(
                      text: 'Go Back',
                      fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                      color: Colors.white,
                ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

  PreferredSizeWidget _buildModernAppBar(BuildContext context, String tappedUserName) {
    return AppBar(
            elevation: 0,
      backgroundColor: const Color(0xFFF8FAFC),
      foregroundColor: const Color(0xFF1E293B),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFF1F5F9),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
      ),
      leading: Container(
        margin: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
            title: Row(
              children: [
                Container(
            width: 45.w,
            height: 45.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
              gradient: const LinearGradient(
                      colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
              size: 22.sp,
                  ),
                ),
                SizedBox(width: 12.w),
          Expanded(
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(
                      text: tappedUserName,
                      fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6.w),
                    CustomText(
                      text: 'Online',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
          Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            CustomText(
                              text: 'Loading messages...',
            fontSize: 16.sp,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      );
                    }

  Widget _buildErrorState(BuildContext context, String error) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.red.shade100,
                  Colors.red.shade50,
                ],
              ),
                              ),
                              child: Icon(
                                Icons.error_outline,
                                size: 40.sp,
              color: Colors.red.shade400,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            CustomText(
                              text: 'Failed to load messages',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                            SizedBox(height: 8.h),
                            CustomText(
                              text: 'Please check your connection and try again',
                              fontSize: 14.sp,
                              color: Colors.grey.shade500,
            textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

  Widget _buildEmptyState(BuildContext context) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.h,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFEEF2FF),
                  Color(0xFFF0F4FF),
                ],
              ),
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 40.sp,
              color: const Color(0xFF6366F1).withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            CustomText(
                              text: 'Start a conversation',
                              fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
                            ),
                            SizedBox(height: 8.h),
                            CustomText(
                              text: 'Send a message to begin chatting',
                              fontSize: 14.sp,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
                            ),
                          ],
                        ),
                      );
                    }

  Widget _buildSendingMessage(BuildContext context, String currentUserId) {
                          return AnimatedBuilder(
      animation: _messageAnimationController,
                            builder: (context, child) {
                              return FadeTransition(
                                opacity: _fadeAnimation,
                                child: SlideTransition(
                                  position: _slideAnimation,
            child: _buildModernMessageBubble(
                                      context,
                                      _msgCtrl.text.trim(),
              true,
                                      Timestamp.now(),
                                      0,
                                      isSending: true,
                                  ),
                                ),
                              );
                            },
                          );
                        }
                        
  Widget _buildAnimatedMessage(
    BuildContext context,
    String message,
    bool isMe,
    Timestamp? timestamp,
    int index,
  ) {
                        return AnimatedBuilder(
      animation: _messageAnimationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: _slideAnimation,
            child: _buildModernMessageBubble(
                                  context,
              message,
                                  isMe,
                                  timestamp,
              index,
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernMessageBubble(
    BuildContext context,
    String message,
    bool isMe,
    Timestamp? timestamp,
    int index, {
    bool isSending = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildUserAvatar(context, false),
            SizedBox(width: 8.w),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isMe ? null : const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                  bottomLeft: isMe ? Radius.circular(20.r) : Radius.circular(6.r),
                  bottomRight: isMe ? Radius.circular(6.r) : Radius.circular(20.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isMe 
                        ? const Color(0xFF6366F1).withOpacity(0.25)
                        : const Color(0xFF1E293B).withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: !isMe ? Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.5,
                ) : null,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 12.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.isNotEmpty ? message : "[empty]",
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontFamily: 'Poppins',
                      color: isMe ? Colors.white : Colors.black87,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isSending) ...[
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 12.w,
                          height: 12.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ),
                        SizedBox(width: 6.w),
                    Text(
                      'Sending...',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontFamily: 'Poppins',
                            color: Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                    ),
                  ],
                  SizedBox(height: 6.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (timestamp != null) ...[
                        Text(
                          _formatTime(timestamp),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isMe 
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade600,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isMe) SizedBox(width: 6.w),
                      ],
                      if (isMe) _buildMessageStatus(timestamp, isSending: isSending),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isMe) ...[
            SizedBox(width: 8.w),
            _buildUserAvatar(context, true),
          ],
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context, bool isMe) {
    return Container(
      width: 36.w,
      height: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
        gradient: isMe
            ? const LinearGradient(
                  colors: [
                  Color(0xFF6366F1),
                  Color(0xFF8B5CF6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isMe ? null : const Color(0xFFE2E8F0),
        boxShadow: [
          BoxShadow(
            color: isMe 
                ? const Color(0xFF6366F1).withOpacity(0.3)
                : const Color(0xFF1E293B).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
              ),
              child: Icon(
                Icons.person,
        size: 18.sp,
        color: isMe ? Colors.white : const Color(0xFF64748B),
      ),
    );
  }

  Widget _buildMessageStatus(Timestamp? messageTimestamp, {bool isSending = false}) {
    if (isSending) {
      return SizedBox(
        width: 12.w,
        height: 12.h,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.7),
          ),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.done_all,
          size: 14.sp,
          color: Colors.white.withOpacity(0.7),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        children: [
          _buildUserAvatar(context, false),
          SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTypingDot(0),
                    SizedBox(width: 4.w),
                    _buildTypingDot(1),
                    SizedBox(width: 4.w),
                    _buildTypingDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        final delay = index * 0.2;
        final animationValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
        final opacity = (animationValue * 2 - 1).abs();
        
        return Container(
          width: 6.w,
          height: 6.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF94A3B8).withOpacity(opacity),
          ),
        );
      },
    );
  }

  Widget _buildModernInputField(BuildContext context, String currentUserId, String tappedUserId) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF1E293B),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(25.r),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _msgCtrl,
                    focusNode: _msgFocus,
                    enabled: !_isSending,
                    textInputAction: TextInputAction.send,
                    minLines: 1,
                    maxLines: 4,
                    onSubmitted: !_isSending ? (_) => _send(currentUserId, tappedUserId) : null,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Poppins',
                      color: const Color(0xFF1E293B),
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF94A3B8),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 16.h,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              AnimatedBuilder(
                animation: _sendButtonScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _sendButtonScaleAnimation.value,
                    child: _isSending
                        ? Container(
                            height: 50.h,
                            width: 50.w,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                height: 20.h,
                                width: 20.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _send(currentUserId, tappedUserId),
                            child: Container(
                              height: 50.h,
                              width: 50.w,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1).withOpacity(0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
