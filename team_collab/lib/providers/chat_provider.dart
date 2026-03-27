import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/message.dart';
import '../services/local_storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalStorageService _localStorageService;
  
  String _activeChatId = 'general';
  List<Message> _messages = [];
  bool _isLoading = true;
  
  Map<String, List<Message>> _allChatMessages = {};

  String get activeChatId => _activeChatId;
  List<Message> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;

  ChatProvider({
    required LocalStorageService localStorageService,
  }) : _localStorageService = localStorageService {
    _listenToAllMessages();
  }

  void setActiveChat(String chatId, String currentUserId) {
    if (_activeChatId == chatId) return;
    _activeChatId = chatId;
    _messages = _allChatMessages[chatId] ?? [];
    markAsRead(chatId, currentUserId);
    notifyListeners();
  }

  void _listenToAllMessages() {
    _db.collection('messages')
        .snapshots()
        .listen((snapshot) {
      final Map<String, List<Message>> newAllMessages = {};
      
      for (var doc in snapshot.docs) {
        try {
          final data = doc.data();
          final msg = Message.fromMap(doc.id, data);
          newAllMessages.putIfAbsent(msg.chatId, () => []).add(msg);
        } catch (e) {
          debugPrint("Error parsing message: $e");
        }
      }

      newAllMessages.forEach((chatId, msgs) {
        msgs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      });

      _allChatMessages = newAllMessages;
      _messages = _allChatMessages[_activeChatId] ?? [];
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to messages: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  int getUnreadCount(String chatId, String userId) {
    final messages = _allChatMessages[chatId] ?? [];
    return messages.where((m) => m.senderId != userId && !m.readBy.contains(userId)).length;
  }

  Future<void> markAsRead(String chatId, String userId) async {
    final unreadMessages = (_allChatMessages[chatId] ?? [])
        .where((m) => m.senderId != userId && !m.readBy.contains(userId))
        .toList();

    if (unreadMessages.isEmpty) return;

    final batch = _db.batch();
    for (var msg in unreadMessages) {
      batch.update(_db.collection('messages').doc(msg.id), {
        'readBy': FieldValue.arrayUnion([userId])
      });
    }
    await batch.commit();
  }

  Future<void> sendMessage(String senderId, String senderName, String content, {MessageType type = MessageType.text, String? fileName}) async {
    try {
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'chatId': _activeChatId,
        'type': type.name,
        'fileName': fileName,
        'readBy': [senderId],
      };
      await _db.collection('messages').add(messageData);
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  Future<void> uploadFile(Uint8List bytes, String filename, String folder) async {
    try {
      // Check file size limit (5MB)
      if (bytes.length > 5242880) {
        throw Exception('File size exceeds 5MB limit');
      }

      final localPath = await _localStorageService.saveBytesLocally(bytes, filename, 'attachment');
      if (localPath == null) {
        throw Exception('Failed to save file locally.');
      }

      final isImage = filename.toLowerCase().endsWith('.jpg') || filename.toLowerCase().endsWith('.jpeg') || filename.toLowerCase().endsWith('.png') || filename.toLowerCase().endsWith('.gif');
      final type = isImage ? MessageType.image : MessageType.file;
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await sendMessage(
          user.uid,
          user.displayName ?? 'Team Member',
          localPath,
          type: type,
          fileName: filename,
        );
      }
    } catch (e) {
      debugPrint("Error in chat uploadFile: $e");
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).delete();
    } catch (e) {
      debugPrint("Error deleting message: $e");
    }
  }

  Future<void> deleteMessageForSelf(String messageId) async {
    try {
      final userId = fb.FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _db.collection('messages').doc(messageId).update({
          'deletedFor': FieldValue.arrayUnion([userId]),
        });
      }
    } catch (e) {
      debugPrint("Error deleting message for self: $e");
    }
  }

  Future<void> deleteMessageForEveryone(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).delete();
    } catch (e) {
      debugPrint("Error deleting message for everyone: $e");
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _db.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
      });
    } catch (e) {
      debugPrint("Error editing message: $e");
    }
  }

  Future<void> removeAttachment(String messageId) async {
    try {
      await _db.collection('messages').doc(messageId).update({
        'type': MessageType.text.name,
        'fileName': null,
        'content': '[Attachment removed]',
        'attachmentRemoved': true,
        'isEdited': true,
      });
    } catch (e) {
      debugPrint("Error removing attachment: $e");
    }
  }

  Future<void> deleteChat(String chatId) async {
    try {
      var snapshots = await _db.collection('messages').where('chatId', isEqualTo: chatId).get();
      for (var doc in snapshots.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint("Error deleting chat: $e");
    }
  }

  String getDmId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id];
    ids.sort();
    return "dm_${ids[0]}_${ids[1]}";
  }
}
