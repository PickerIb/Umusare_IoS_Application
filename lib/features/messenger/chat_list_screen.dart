import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_service.dart';
import 'chat_detail_screen.dart';
import '../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'Chats',
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService().getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading chats', style: TextStyle(color: Colors.red)));
          }
          final chats = snapshot.data ?? [];
          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline, color: theme.colorScheme.primary, size: 54),
                          const SizedBox(height: 18),
                          Text(
                            'No chats yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start a conversation with a seller or support. Your chats will appear here.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final chat = chats[i];
              final participants = List<String>.from(chat['participants'] ?? []);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid;
              final otherUserId = participants.firstWhere((id) => id != currentUserId, orElse: () => '');
              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserInfo(otherUserId),
                builder: (context, userSnapshot) {
                  final user = userSnapshot.data;
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary,
                        backgroundImage: user != null && user['avatarUrl'] != null && user['avatarUrl'] != ''
                            ? NetworkImage(user['avatarUrl'])
                            : null,
                        child: user == null
                            ? Icon(Icons.person, color: theme.colorScheme.onPrimary)
                            : Text(user['name'] != null && user['name'].isNotEmpty ? user['name'][0].toUpperCase() : '',
                                style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        user != null && user['name'] != null ? user['name'] : 'User',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.colorScheme.onSurface),
                      ),
                      subtitle: Text(
                        chat['lastMessage'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      ),
                      trailing: chat['lastTimestamp'] != null
                          ? Text(
                              _formatTimestamp(chat['lastTimestamp']),
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.5)),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              chatId: chat['id'],
                              participants: chat['participants'] ?? [],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
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

Future<Map<String, dynamic>?> _fetchUserInfo(String userId) async {
  if (userId.isEmpty) return null;
  // Simulate fetching user info from Firestore 'users' collection
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.exists ? doc.data() : null;
} 