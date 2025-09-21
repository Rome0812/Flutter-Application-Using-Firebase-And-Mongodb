import "package:cloud_firestore/cloud_firestore.dart";

enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
}

class MessageModel {
  final String senderId;
  final String senderEmail;
  final String receiverId;
  final String message;
  final Timestamp timestamp;
  final MessageStatus status;
  final String? messageId;
  final bool isEdited;
  final Timestamp? editedAt;
 
  MessageModel({
    required this.senderId,
    required this.senderEmail,
    required this.receiverId,
    required this.message,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.messageId,
    this.isEdited = false,
    this.editedAt,
  });
 
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      senderEmail: map['senderEmail'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${map['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
      messageId: map['messageId'],
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'],
    );
  }
 
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderEmail': senderEmail,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp,
      'status': status.toString().split('.').last,
      'messageId': messageId,
      'isEdited': isEdited,
      'editedAt': editedAt,
    };
  }

  MessageModel copyWith({
    String? senderId,
    String? senderEmail,
    String? receiverId,
    String? message,
    Timestamp? timestamp,
    MessageStatus? status,
    String? messageId,
    bool? isEdited,
    Timestamp? editedAt,
  }) {
    return MessageModel(
      senderId: senderId ?? this.senderId,
      senderEmail: senderEmail ?? this.senderEmail,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      messageId: messageId ?? this.messageId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
    );
  }
}