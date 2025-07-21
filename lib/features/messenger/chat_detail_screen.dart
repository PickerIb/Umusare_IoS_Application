import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final List<dynamic> participants;
  const ChatDetailScreen({super.key, required this.chatId, required this.participants});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isSending = true);
    await ChatService().sendMessage(widget.chatId, text);
    _messageController.clear();
    setState(() => _isSending = false);
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text('Chat', style: theme.appBarTheme.titleTextStyle),
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: ChatService().getMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages', style: TextStyle(color: Colors.red)));
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return Center(
                    child: Text('No messages yet. Start the conversation!', style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7))),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg['senderId'] == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? theme.colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                                fontSize: 16,
                              ),
                            ),
                            if (msg['timestamp'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  _formatTimestamp(msg['timestamp']),
                                  style: TextStyle(
                                    color: isMe ? theme.colorScheme.onPrimary.withOpacity(0.7) : theme.colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: theme.cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: theme.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                          )
                        : Icon(Icons.send, color: theme.colorScheme.primary, size: 28),
                    onPressed: _isSending ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    final dt = timestamp.toDate();
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
  return '';
} 