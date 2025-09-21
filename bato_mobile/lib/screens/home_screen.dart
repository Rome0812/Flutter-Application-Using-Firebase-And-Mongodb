import 'package:bato_advmobprog/screens/chat_screen.dart';

import 'settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'article_screen.dart';
import '../widgets/custom_text.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, this.username = ''});
 
  @override
  State<HomeScreen> createState() => HomeScreenState();
}
 
class HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  final PageController pageController = PageController();
  final GlobalKey<ProfileScreenState> profileKey = GlobalKey<ProfileScreenState>();
 
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: CustomText(     
          text: selectedIndex == 0 ? 'Articles' : selectedIndex == 2 ? 'Profile' : 'Chats',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: selectedIndex == 2 
              ? (profileKey.currentState?.isEditMode ?? false ? const Icon(Icons.close) : const Icon(Icons.edit))
              : const Icon(Icons.settings),
            onPressed: () {
              if (selectedIndex == 2) {
                // Toggle edit mode for profile screen
                profileKey.currentState?.toggleEditMode();
              } else {
                // Navigate to settings screen for other tabs
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const settings_screen(), 
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: PageView(
        controller: pageController,
        children: <Widget>[
          const ArticleScreen(), 
          const ChatScreen(), 
          ProfileScreen(
            key: profileKey,
            onEditModeChanged: () {
              setState(() {}); // Refresh the UI to update the icon
            },
          )
        ],
        onPageChanged: (page) {
          setState(() {
            selectedIndex = page;
          });
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: onTappedBar,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: selectedIndex,
      ),
    );
  }
 
  void onTappedBar(int value) {
    setState(() {
      selectedIndex = value;
    });
    pageController.jumpToPage(value);
  }
}