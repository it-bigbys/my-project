import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AuthProvider>().currentUser!;
    context.read<ChatProvider>().sendMessage(user.id, user.name, text);
    _controller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = context.watch<ChatProvider>().messages;
    final currentUser = context.watch<AuthProvider>().currentUser;

    return ResponsiveScaffold(
      title: 'General Chat',
      currentRoute: '/chat',
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg.senderId == currentUser?.id;
                
                String initials = '??';
                if (msg.senderName.trim().isNotEmpty) {
                  final parts = msg.senderName.trim().split(' ');
                  initials = parts.map((e) => e.isNotEmpty ? e[0] : '').join().toUpperCase();
                  if (initials.length > 2) initials = initials.substring(0, 2);
                }

                return _MessageBubble(
                  senderName: msg.senderName,
                  content: msg.content,
                  timestamp: msg.timestamp,
                  isMe: isMe,
                  initials: initials,
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            color: const Color(0xFF1E293B),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Message #general',
                    hintStyle: const TextStyle(color: Color(0xFF475569)),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String senderName;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  final String initials;

  const _MessageBubble({required this.senderName, required this.content, required this.timestamp, required this.isMe, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFF6366F1), child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMe) Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: Text(senderName, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(DateFormat('h:mm a').format(timestamp), style: const TextStyle(color: Color(0xFF475569), fontSize: 10)),
              ),
            ],
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 14, backgroundColor: const Color(0xFF6366F1), child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ],
      ),
    );
  }
}
