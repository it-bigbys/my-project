import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String content; // For text, it's the message. For image/file, it's Base64 data.
  final DateTime timestamp;
  final String chatId;
  final MessageType type;
  final String? fileName;
  final List<String> readBy;
  final bool isEdited;
  final List<String> deletedFor; // List of user IDs who deleted this message for themselves
  final bool attachmentRemoved; // True if attachment was removed but message kept

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    required this.chatId,
    this.type = MessageType.text,
    this.fileName,
    this.readBy = const [],
    this.isEdited = false,
    this.deletedFor = const [],
    this.attachmentRemoved = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'type': type.name,
      'fileName': fileName,
      'readBy': readBy,
      'isEdited': isEdited,
      'deletedFor': deletedFor,
      'attachmentRemoved': attachmentRemoved,
    };
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    DateTime parsedTime = DateTime.now();
    if (map['timestamp'] is Timestamp) {
      parsedTime = (map['timestamp'] as Timestamp).toDate();
    } else if (map['timestamp'] is String) {
      parsedTime = DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    }

    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      content: map['content'] ?? '',
      timestamp: parsedTime,
      chatId: map['chatId'] ?? 'general',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'], 
        orElse: () => MessageType.text
      ),
      fileName: map['fileName'],
      readBy: List<String>.from(map['readBy'] ?? []),
      isEdited: map['isEdited'] ?? false,
      deletedFor: List<String>.from(map['deletedFor'] ?? []),
      attachmentRemoved: map['attachmentRemoved'] ?? false,
    );
  }
}
