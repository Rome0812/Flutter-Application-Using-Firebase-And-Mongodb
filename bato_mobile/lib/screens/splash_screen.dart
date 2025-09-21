import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/user_service.dart';
 
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
 
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
 
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    getIsLogin();
  }
 
  Future<void> getIsLogin() async {
    final userData = await UserService().getUserData();
 
    if (userData['token'] != null && userData['token'] != '') {
      // User is logged in
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/home'),
      );
    } else {
      // User is not logged in
      Timer(
        const Duration(seconds: 4),
        () => Navigator.popAndPushNamed(context, '/login'),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue, Colors.lightBlue],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with better spacing and shadow
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: ScreenUtil().setHeight(120),
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // Centered loading indicator with text
            Column(
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}