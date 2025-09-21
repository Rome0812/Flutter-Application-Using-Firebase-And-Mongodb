import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

ValueNotifier<UserService> userService = ValueNotifier(UserService());

class UserService {
  Map<String, dynamic> data = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
 
  /// **Login User**
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    Response response = await post(
      Uri.parse('$host/api/users/login'),
      body: {"email": email, "password": password},
    );
 
    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to load data: ${response.statusCode} ${response.body}');
    }
  }

  /// **Register User**
 Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String age,
    required String gender,
    required String contactNumber,
    required String email,
    required String username,
    required String password,
    required String address,
    String type = 'editor', 
  }) async {
    Response response = await post(
      Uri.parse('$host/api/users/register'), 
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
        'contactNumber': contactNumber,
        'email': email,
        'username': username,
        'password': password,
        'address': address,
        'type': type,
      }),
    );

    if (response.statusCode == 201) {
      data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception('Failed to register user: ${response.statusCode}');
    }
  }
  /// **Update User (MongoDB)**
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    final response = await post(
      Uri.parse('$host/api/users/${userData['uid'] ?? userData['_id']}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "firstName": userData['firstName'],
        "lastName": userData['lastName'],
        "age": userData['age'],
        "gender": userData['gender'],
        "contactNumber": userData['contactNumber'],
        "email": userData['email'],
        "username": userData['username'],
        "password": userData['password'], // ⚠️ Only include if updating password
        "address": userData['address'],
        "isActive": userData['isActive'] ?? true,
        "type": userData['type'] ?? 'viewer',
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Save updated user in SharedPreferences
      await saveUserData(data);

      return data;
    } else {
      throw Exception(
        'Failed to update user: ${response.statusCode} ${response.body}',
      );
    }
  }
  Future<void> deleteUser(String userId) async {
    final response = await delete(
      Uri.parse('$host/api/users/$userId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      await logout();
    } else {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }

  /// **Delete User Account (MongoDB)**
  Future<void> deleteUserMongoDB(String userId) async {
    final response = await delete(
      Uri.parse('$host/api/users/$userId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      await logout();
    } else {
      throw Exception('Failed to delete user: ${response.statusCode}');
    }
  }
    /// **Save User Data to SharedPreferences and Firestore**
 Future<void> saveUserData(Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Store the appropriate ID based on the data source
    await prefs.setString('uid', userData['uid'] ?? userData['_id'] ?? '');
    await prefs.setString('_id', userData['_id'] ?? ''); // Store MongoDB _id separately
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('lastName', userData['lastName'] ?? '');
    await prefs.setString('age', userData['age'] ?? '');
    await prefs.setString('gender', userData['gender'] ?? '');
    await prefs.setString('contactNumber', userData['contactNumber'] ?? '');
    await prefs.setString('email', userData['email'] ?? '');
    await prefs.setString('username', userData['username'] ?? '');
    await prefs.setString('address', userData['address'] ?? '');
    await prefs.setBool('isActive', userData['isActive'] == true);
    await prefs.setString('type', userData['type'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('loginType', userData['loginType'] ?? 'mongodb');
    // Add a flag to distinguish between Firebase and MongoDB
    await prefs.setBool('isFirebaseAuth', userData['isFirebaseAuth'] == true);
    
    // Also save to Firestore for chat functionality
    await _saveUserToFirestore(userData);
  }

  /// Retrieve User Data from SharedPreferences
  Future<Map<String, dynamic>> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final userData = {
      'uid': prefs.getString('uid') ?? '',
      '_id': prefs.getString('_id') ?? '',
      'firstName': prefs.getString('firstName') ?? '',
      'lastName': prefs.getString('lastName') ?? '',
      'age': prefs.getString('age') ?? '',
      'gender': prefs.getString('gender') ?? '',
      'contactNumber': prefs.getString('contactNumber') ?? '',
      'email': prefs.getString('email') ?? '',
      'username': prefs.getString('username') ?? '',
      'address': prefs.getString('address') ?? '',
      'isActive': prefs.getBool('isActive') ?? false,
      'type': prefs.getString('type') ?? '',
      'token': prefs.getString('token') ?? '',
      'isFirebaseAuth': prefs.getBool('isFirebaseAuth') ?? false,
    };

    // print("Retrieved User Data: $userData"); // DEBUG
    return userData;
  }
  /// **Check if User is Logged In**
  Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') != null;
  }
 
  /// **Logout and Clear User Data**
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// **Clear Authentication Data (for testing)**
  Future<void> clearAuthData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isFirebaseAuth');
    await prefs.remove('uid');
    await prefs.remove('_id');
    await prefs.remove('token');
    print("DEBUG: Cleared authentication data");
  }
  // Your previous code
  // Just add this code under the previous code
 
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
 
  User? get currentUser => firebaseAuth.currentUser;
 
  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();
 
  /// **Firebase Sign In**
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Save user data to SharedPreferences if needed
      if (result.user != null) {
        await saveUserData({
          'uid': result.user!.uid,
          'email': result.user!.email ?? '',
          'firstName': result.user!.displayName?.split(' ').first ?? '',
          'lastName': result.user!.displayName?.split(' ').skip(1).join(' ') ?? '',
          'username': result.user!.displayName ?? '',
          'token': await result.user!.getIdToken(),
          'isFirebaseAuth': true,
        });
      }
      
      return result;
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }
 
  /// **Firebase Create Account**
  Future<UserCredential> createAccount({
    required String email,
    required String password,
    String? displayName,
    String? username,
    String? firstName,
    String? lastName,
    String? age,
    String? gender,
    String? contactNumber,
    String? address,
    String? type = 'editor',
  }) async {
    try {
      final UserCredential result = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      // Update display name if provided
      if (displayName != null && result.user != null) {
        await result.user!.updateDisplayName(displayName);
        await result.user!.reload();
      }
      
      // Save user data to SharedPreferences
      if (result.user != null) {
        await saveUserData({
          'uid': result.user!.uid,
          'email': result.user!.email ?? '',
          'firstName': firstName ?? displayName?.split(' ').first ?? '',
          'lastName': lastName ?? displayName?.split(' ').skip(1).join(' ') ?? '',
          'username': username ?? '',
          'age': age ?? '',
          'gender': gender ?? '',
          'contactNumber': contactNumber ?? '',
          'address': address ?? '',
          'type': type ?? 'editor',
          'token': await result.user!.getIdToken(),
          'isFirebaseAuth': true,
        });
      }
      
      return result;
    } catch (e) {
      throw Exception('Account creation failed: ${e.toString()}');
    }
  }
 
  /// **Firebase Sign Out**
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
      await logout(); // Clear SharedPreferences as well
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }
 
  /// **Update Username/Display Name (Firebase)**
  Future<void> updateUsername({required String username}) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }
      
      await currentUser!.updateDisplayName(username);
      await currentUser!.reload();
      
      // Update SharedPreferences with new username
      final userData = await getUserData();
      userData['username'] = username;
      // Don't update firstName and lastName when changing username
      await saveUserData(userData);
      
    } catch (e) {
      throw Exception('Username update failed: ${e.toString()}');
    }
  }

  /// **Update Username (MongoDB)**
  Future<Map<String, dynamic>> updateUsernameMongoDB({
    required String userId,
    required String username,
  }) async {
    try {
      print('Host value: $host'); // Debug print
      print('Updating username for user ID: $userId'); // Debug print
      print('New username: $username'); // Debug print
      print('API URL: $host/api/users/$userId/username'); // Debug print
      
      final response = await put(
        Uri.parse('$host/api/users/$userId/username'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'username': username,
        }),
      );

      print('Response status: ${response.statusCode}'); // Debug print
      print('Response body: ${response.body}'); // Debug print

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Update SharedPreferences with new username
        final userData = await getUserData();
        userData['username'] = username;
        await saveUserData(userData);
        
        return data;
      } else {
        throw Exception('Failed to update username: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error in updateUsernameMongoDB: $e'); // Debug print
      throw Exception('Username update failed: ${e.toString()}');
    }
  }

  /// **Change Password (MongoDB)**
  Future<Map<String, dynamic>> changePasswordMongoDB({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await put(
        Uri.parse('$host/api/users/$userId/password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to change password: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Password change failed: ${e.toString()}');
    }
  }

  /// Save user data to Firestore Users collection
  Future<void> _saveUserToFirestore(Map<String, dynamic> userData) async {
    try {
      final uid = userData['uid'] ?? '';
      if (uid.isNotEmpty) {
        await _firestore.collection('Users').doc(uid).set({
          'uid': uid,
          'firstName': userData['firstName'] ?? '',
          'lastName': userData['lastName'] ?? '',
          'email': userData['email'] ?? '',
          'type': userData['type'] ?? 'admin',
          'loginType': userData['loginType'] ?? 'mongodb',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to update existing documents
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
      // Don't throw error as this shouldn't break the main flow
    }
  }
  /// Sync current user data to Firestore (useful for existing MongoDB users)
  Future<void> syncCurrentUserToFirestore() async {
    try {
      final userData = await getUserData();
      if (userData['uid'] != null && userData['uid'].toString().isNotEmpty) {
        await _saveUserToFirestore(userData);
        print('✅ User synced to Firestore successfully');
      }
    } catch (e) {
      print('❌ Error syncing user to Firestore: $e');
    }
  }
  /// **Delete Account**
  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.delete();
      await logout(); // Clear SharedPreferences
      
    } catch (e) {
      throw Exception('Account deletion failed: ${e.toString()}');
    }
  }
 
  /// **Reset Password from Current Password**
  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('No user is currently signed in');
      }
      
      print('DEBUG: Attempting Firebase password change for email: $email');
      print('DEBUG: Current user UID: ${currentUser!.uid}');
      
      AuthCredential credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: currentPassword,
      );

      print('DEBUG: Reauthenticating user...');
      await currentUser!.reauthenticateWithCredential(credential);
      
      print('DEBUG: Updating password...');
      await currentUser!.updatePassword(newPassword);
      
      print('DEBUG: Password updated successfully');
      
    } catch (e) {
      print('DEBUG: Firebase password change error: $e');
      throw Exception('Password reset failed: ${e.toString()}');
    }
  }

  /// **Send Password Reset Email**
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Exception('Password reset email failed: ${e.toString()}');
    }
  }
}