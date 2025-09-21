import 'package:bato_advmobprog/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Get current user ID consistently (same as chat detail screen)
  Future<String> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid') ?? '';
      
      if (uid.isNotEmpty) {
        return uid;
      }
      
      // Fallback to Firebase Auth
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        print('Using Firebase Auth UID as fallback: ${firebaseUser.uid}');
        return firebaseUser.uid;
      }
      
      throw Exception('No user ID found in local storage or Firebase Auth');
    } catch (e) {
      print('Error getting current user ID: $e');
      rethrow;
    }
  }

  // Get all users
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    final String currentUserId = await _getCurrentUserId();
    final String? currentUserEmail = _firebaseAuth.currentUser?.email;
    final Timestamp timestamp = Timestamp.now();

    // Create a new message model
    MessageModel newMessage = MessageModel(
      senderId: currentUserId,
      senderEmail: currentUserEmail ?? '',
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
    );

    // Construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [currentUserId, receiverId];
    ids.sort(); // Sort the ids to ensure the chatRoomID is the same for any 2 people
    String chatRoomID = ids.join("_");

    print('📤 Sending message:');
    print('  Current User ID: $currentUserId');
    print('  Receiver ID: $receiverId');
    print('  Chat Room ID: $chatRoomID');
    print('  Message: $message');

    // Add new message to Firestore
    await _firestore
        .collection("chat rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // Get messages
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // Construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [userID, otherUserID];
    ids.sort(); // Sort the ids to ensure the chatRoomID is the same for any 2 people
    String chatRoomID = ids.join("_");

    print('📥 Getting messages:');
    print('  User ID: $userID');
    print('  Other User ID: $otherUserID');
    print('  Chat Room ID: $chatRoomID');

    // Return messages from Firestore, ordered by timestamp
    return _firestore
        .collection("chat rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get UID by email
  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) return null;

    // Ensure your Users doc actually stores the Firebase Auth UID in a field 'uid'
    return (q.docs.first.data()['uid'] ?? '').toString();
  }

  // Debug method to list all chat rooms
  Future<void> debugListChatRooms() async {
    try {
      final chatRooms = await _firestore.collection("chat rooms").get();
      print('🔍 Available Chat Rooms:');
      for (var room in chatRooms.docs) {
        print('  Room ID: ${room.id}');
        final messages = await room.reference.collection("messages").get();
        print('    Messages count: ${messages.docs.length}');
      }
    } catch (e) {
      print('❌ Error listing chat rooms: $e');
    }
  }
}
