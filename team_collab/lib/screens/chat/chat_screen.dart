import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../models/user.dart' as model;
import '../../models/message.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/attachment_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage({MessageType type = MessageType.text, String? fileName, String? base64Data}) {
    final text = _controller.text.trim();
    if (text.isEmpty && type == MessageType.text && base64Data == null) return;
    
    final user = context.read<AuthProvider>().currentUser!;
    context.read<ChatProvider>().sendMessage(
      user.id, 
      user.name, 
      type == MessageType.text ? text : (base64Data ?? ''),
      type: type,
      fileName: fileName,
    );
    _controller.clear();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      final fileSizeMB = (bytes.length / 1048576).toStringAsFixed(2);
      
      if (bytes.length > 5242880) {
        if (mounted) {
          _showFileSizeWarning(context, pickedFile.name, fileSizeMB);
        }
        return;
      }

      await context.read<ChatProvider>().uploadFile(bytes, pickedFile.name, 'attachment');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final bytes = result.files.single.bytes;
      if (bytes != null) {
        final fileSizeMB = (bytes.length / 1048576).toStringAsFixed(2);
        
        if (bytes.length > 5242880) {
          if (mounted) {
            _showFileSizeWarning(context, result.files.single.name, fileSizeMB);
          }
          return;
        }

        await context.read<ChatProvider>().uploadFile(bytes, result.files.single.name, 'attachment');
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showFileSizeWarning(BuildContext context, String fileName, String fileSizeMB) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.warning_rounded, color: Colors.orange, size: 40),
        title: const Text('File Too Large'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The file "$fileName" is too large to upload.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('File size:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text('$fileSizeMB MB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max allowed:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const Text('5.00 MB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please compress the file or choose a smaller file and try again.',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final theme = Theme.of(context);
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return ResponsiveScaffold(
      title: 'Team Chat',
      currentRoute: '/chat',
      body: Row(
        children: [
          if (!isMobile)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(right: BorderSide(color: theme.dividerColor)),
              ),
              child: _buildChatList(chatProvider, authProvider),
            ),
          
          Expanded(
            child: Column(
              children: [
                // Chat Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(bottom: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Row(
                    children: [
                      if (isMobile) 
                        IconButton(
                          icon: const Icon(Icons.menu_open, size: 20),
                          onPressed: () => _showMobileChannels(context, chatProvider, authProvider),
                        ),
                      Icon(
                        chatProvider.activeChatId.startsWith('dm_') ? Icons.person_rounded : Icons.tag_rounded,
                        size: 20, 
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: chatProvider.activeChatId.startsWith('dm_') ? () => _showUserInfo(context, chatProvider.activeChatId, authProvider) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getChatTitle(chatProvider.activeChatId, authProvider),
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (chatProvider.activeChatId.startsWith('dm_'))
                                const Text('View profile info', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.grey, size: 20),
                        onPressed: () => _confirmDeleteChat(context, chatProvider),
                        tooltip: 'Clear history',
                      ),
                    ],
                  ),
                ),

                // Messages List
                Expanded(
                  child: chatProvider.isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatProvider.messages[index];
                          final isMe = msg.senderId == currentUser?.id;
                          
                          // Skip messages deleted by current user
                          if (msg.deletedFor.contains(currentUser?.id)) {
                            return const SizedBox.shrink();
                          }
                          
                          return _MessageBubble(
                            message: msg,
                            isMe: isMe,
                            currentUserId: currentUser?.id ?? '',
                            onDeleteForSelf: () => chatProvider.deleteMessageForSelf(msg.id),
                            onDeleteForEveryone: () => chatProvider.deleteMessageForEveryone(msg.id),
                            onEdit: (newText) => chatProvider.editMessage(msg.id, newText),
                            onRemoveAttachment: () => chatProvider.removeAttachment(msg.id),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
                        },
                      ),
                ),

                // Input Area
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                            onPressed: () => _showAttachmentOptions(context),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Message #${_getChatTitle(chatProvider.activeChatId, authProvider)}',
                                hintStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _sendMessage(),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: theme.primaryColor, shape: BoxShape.circle),
                              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF800000)),
              title: const Text('Camera'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: Colors.blue),
              title: const Text('Gallery'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.file_present_outlined, color: Colors.orange),
              title: const Text('File'),
              onTap: () { Navigator.pop(context); _pickFile(); },
            ),
          ],
        ),
      ),
    );
  }

  void _showUserInfo(BuildContext context, String chatId, AuthProvider auth) {
    final parts = chatId.split('_');
    final otherUserId = parts[1] == auth.currentUser?.id ? parts[2] : parts[1];
    final member = auth.teamMembers.firstWhere((m) => m.id == otherUserId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 40, backgroundColor: Theme.of(context).primaryColor, child: Text(member.avatarInitials, style: const TextStyle(fontSize: 24, color: Colors.white))),
            const SizedBox(height: 16),
            Text(member.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(member.role, style: const TextStyle(color: Colors.grey)),
            const Divider(height: 32),
            _infoRow(Icons.email_outlined, member.email),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 8),
      Text(text, style: const TextStyle(fontSize: 14)),
    ]);
  }

  void _confirmDeleteChat(BuildContext context, ChatProvider chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text('This will delete all messages in this conversation for everyone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { chat.deleteChat(chat.activeChatId); Navigator.pop(context); }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  String _getChatTitle(String chatId, AuthProvider auth) {
    if (chatId == 'general') return 'general';
    if (chatId.startsWith('dm_')) {
      final parts = chatId.split('_');
      final otherUserId = parts[1] == auth.currentUser?.id ? parts[2] : parts[1];
      try {
        return auth.teamMembers.firstWhere((m) => m.id == otherUserId).name;
      } catch (_) {
        return 'Direct Message';
      }
    }
    return 'Chat';
  }

  void _showMobileChannels(BuildContext context, ChatProvider chat, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: _buildChatList(chat, auth),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(ChatProvider chat, AuthProvider auth) {
    final theme = Theme.of(context);
    final currentUserId = auth.currentUser?.id ?? '';
    
    final allMembers = auth.teamMembers.where((m) => m.id != currentUserId).toList();
    final filteredMembers = _searchController.text.isEmpty 
        ? allMembers 
        : allMembers.where((m) => m.name.toLowerCase().contains(_searchController.text.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search members...',
              prefixIcon: const Icon(Icons.search, size: 18),
              filled: true,
              fillColor: theme.scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('CHANNELS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        ),
        _buildChatItem(
          icon: Icons.tag_rounded,
          label: 'general',
          isActive: chat.activeChatId == 'general',
          unreadCount: chat.getUnreadCount('general', currentUserId),
          onTap: () {
            chat.setActiveChat('general', currentUserId);
            if (MediaQuery.of(context).size.width < 800) Navigator.pop(context);
          },
        ),
        
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('TEAM MEMBERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
        ),
        ...filteredMembers.map((member) {
          final dmId = chat.getDmId(currentUserId, member.id);
          
          // Create image provider for member's profile picture
          ImageProvider<Object>? memberImage;
          if (member.photoLocalPath != null && !kIsWeb && File(member.photoLocalPath!).existsSync()) {
            memberImage = FileImage(File(member.photoLocalPath!));
          } else if (member.photoUrl != null && member.photoUrl!.isNotEmpty) {
            if (member.photoUrl!.startsWith('data:')) {
              memberImage = NetworkImage(member.photoUrl!);
            } else if (!kIsWeb && File(member.photoUrl!).existsSync()) {
              memberImage = FileImage(File(member.photoUrl!));
            }
          }
          
          return _buildChatItem(
            avatarImage: memberImage,
            avatar: memberImage == null ? member.avatarInitials : null,
            label: member.name,
            isActive: chat.activeChatId == dmId,
            unreadCount: chat.getUnreadCount(dmId, currentUserId),
            onTap: () {
              chat.setActiveChat(dmId, currentUserId);
              if (MediaQuery.of(context).size.width < 800) Navigator.pop(context);
            },
          );
        }),
      ],
    );
  }

  Widget _buildChatItem({IconData? icon, ImageProvider<Object>? avatarImage, String? avatar, required String label, required bool isActive, required int unreadCount, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(left: BorderSide(color: isActive ? theme.primaryColor : Colors.transparent, width: 3)),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 20, color: isActive ? theme.primaryColor : Colors.grey),
            if (avatarImage != null)
              CircleAvatar(radius: 12, backgroundImage: avatarImage, backgroundColor: theme.primaryColor)
            else if (avatar != null) 
              CircleAvatar(radius: 12, backgroundColor: theme.primaryColor, child: Text(avatar, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label, 
                style: TextStyle(
                  fontSize: 14, 
                  fontWeight: isActive || unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                  color: isActive || unreadCount > 0 ? theme.textTheme.bodyLarge?.color : Colors.grey,
                ),
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(10)),
                child: Text('$unreadCount', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            else if (isActive) 
              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final VoidCallback onDeleteForSelf;
  final VoidCallback onDeleteForEveryone;
  final Function(String) onEdit;
  final VoidCallback onRemoveAttachment;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.onDeleteForSelf,
    required this.onDeleteForEveryone,
    required this.onEdit,
    required this.onRemoveAttachment,
  });

  Widget _buildAvatar(BuildContext context, String userId, String userName) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    
    // Get user data
    model.User? user;
    if (isMe) {
      user = authProvider.currentUser;
    } else {
      user = authProvider.teamMembers.firstWhere(
        (member) => member.id == userId,
        orElse: () => model.User(id: '', name: '', email: '', role: '', photoUrl: null, photoLocalPath: null),
      );
    }

    // Create image provider if user has photo
    ImageProvider<Object>? imageProvider;
    if (user?.photoLocalPath != null && !kIsWeb && File(user!.photoLocalPath!).existsSync()) {
      imageProvider = FileImage(File(user.photoLocalPath!));
    } else if (user?.photoUrl != null && user!.photoUrl!.isNotEmpty) {
      if (user.photoUrl!.startsWith('data:')) {
        // Data URL for web
        imageProvider = NetworkImage(user.photoUrl!);
      } else if (!kIsWeb && File(user.photoUrl!).existsSync()) {
        // Local file path
        imageProvider = FileImage(File(user.photoUrl!));
      }
    }

    if (imageProvider != null) {
      return CircleAvatar(
        radius: 14,
        backgroundImage: imageProvider,
        backgroundColor: theme.primaryColor,
      );
    } else {
      // Fallback to initials
      final initials = userName.isNotEmpty ? userName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '??';
      return CircleAvatar(
        radius: 14,
        backgroundColor: theme.primaryColor,
        child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onLongPress: isMe ? () => _showOptionsMenu(context) : null,
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              _buildAvatar(context, message.senderId, message.senderName),
              const SizedBox(width: 8),
            ],
            Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe) Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(message.senderName, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
                _buildMessageContent(context),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.timestamp),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        const Text(
                          '(edited)',
                          style: TextStyle(color: Colors.grey, fontSize: 9, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isMe) ...[
              const SizedBox(width: 8),
              _buildAvatar(context, message.senderId, message.senderName),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final theme = Theme.of(context);
    
    if (message.attachmentRemoved) {
      return Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.primaryColor : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
        ),
        child: Text(
          '[Attachment removed]',
          style: TextStyle(
            color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    if (message.type == MessageType.image || message.type == MessageType.file) {
      return AttachmentWidget(
        filePath: message.content,
        fileName: message.fileName,
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? theme.primaryColor : theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: isMe ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        message.content, 
        style: TextStyle(color: isMe ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color, fontSize: 14),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    final hasAttachment = message.type == MessageType.image || message.type == MessageType.file;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.blue),
              title: const Text('Edit Message'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context);
              },
            ),
            const Divider(height: 1),
            if (hasAttachment) ...[
              ListTile(
                leading: const Icon(Icons.image_not_supported_outlined, color: Colors.purple),
                title: const Text('Remove Attachment'),
                subtitle: const Text('Message text will be kept', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  onRemoveAttachment();
                },
              ),
              const Divider(height: 1),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Delete for Me Only'),
              subtitle: const Text('You won\'t see this message', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                onDeleteForSelf();
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('Delete for Everyone'),
              subtitle: const Text('Everyone will see it\'s deleted', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete for Everyone?'),
        content: const Text('Once deleted, this message cannot be recovered.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteForEveryone();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(controller: editController, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { onEdit(editController.text); Navigator.pop(context); }, child: const Text('Save')),
        ],
      ),
    );
  }
}
