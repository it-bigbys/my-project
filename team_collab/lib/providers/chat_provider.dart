import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Message> _messages = [];
  bool _isLoading = true;

  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatProvider() {
    _listenToMessages();
  }

  void _listenToMessages() {
    _db.collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snapshot) {
      _messages = snapshot.docs.map((doc) => Message.fromMap(doc.id, doc.data())).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> sendMessage(String senderId, String senderName, String content) async {
    try {
      final message = Message(
        id: '',
        senderId: senderId,
        senderName: senderName,
        content: content,
        timestamp: DateTime.now(),
      );
      await _db.collection('messages').add(message.toMap());
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }
}
