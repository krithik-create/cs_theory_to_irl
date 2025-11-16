import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = prefs.getStringList('chat_conversations') ?? [];

    setState(() {
      _conversations = conversations.map((conv) {
        return Map<String, dynamic>.from(json.decode(conv));
      }).toList();

      // Sort by timestamp (most recent first)
      _conversations.sort((a, b) {
        DateTime aTime = DateTime.parse(a['timestamp']);
        DateTime bTime = DateTime.parse(b['timestamp']);
        return bTime.compareTo(aTime);
      });
    });
  }

  Future<void> _deleteConversation(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final conversations = prefs.getStringList('chat_conversations') ?? [];

    if (index >= 0 && index < conversations.length) {
      conversations.removeAt(index);

      await prefs.setStringList('chat_conversations', conversations);
      await _loadChatHistory();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversation deleted')),
        );
      }
    }
  }

  Future<void> _clearAllHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_conversations');

    setState(() {
      _conversations = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All conversations cleared')),
      );
    }
  }

  String _getConversationPreview(Map<String, dynamic> conversation) {
    final messages = List<Map<String, dynamic>>.from(conversation['messages'] ?? []);
    if (messages.isEmpty) return 'No messages';

    // Find first user message for preview
    for (var message in messages) {
      if (message['type'] == 'user') {
        String preview = message['message']?.toString() ?? '';
        return preview.length > 60 ? '${preview.substring(0, 60)}...' : preview;
      }
    }

    return 'Conversation started';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        actions: [
          if (_conversations.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Theme.of(context).iconTheme.color),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Clear All History'),
                      content: const Text('Are you sure you want to delete all chat history? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _clearAllHistory();
                          },
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Clear All'),
                        ),
                      ],
                    );
                  },
                );
              },
              tooltip: 'Clear all history',
            ),
        ],
      ),
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.background,
          ],
        ),
      ),
        child: _conversations.isEmpty
            ? _buildEmptyState()
            : _buildHistoryList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Start chatting with the AI to see your history here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Subjects'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final conversation = _conversations[index];
        final subject = conversation['subject'] ?? 'Unknown Subject';
        final grade = conversation['grade'] ?? 'Unknown Grade';
        final timestamp = DateTime.parse(conversation['timestamp']);
        final messageCount = (conversation['messages'] as List).length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$subject - Grade $grade',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${messageCount} messages • ${_formatDate(timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteConversation(index);
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _getConversationPreview(conversation),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _openConversation(conversation);
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Continue Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        _viewConversation(conversation);
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _openConversation(Map<String, dynamic> conversation) {
    final subject = conversation['subject'];
    final grade = conversation['grade'];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AIChatPage(
          subject: subject,
          grade: grade,
          existingConversation: conversation,
        ),
      ),
    );
  }

  void _viewConversation(Map<String, dynamic> conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConversationViewPage(conversation: conversation),
      ),
    );
  }
}

class ConversationViewPage extends StatefulWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback? onContinue;

  const ConversationViewPage({
    super.key,
    required this.conversation,
    this.onContinue,
  });

  @override
  State<ConversationViewPage> createState() => _ConversationViewPageState();
}

class _ConversationViewPageState extends State<ConversationViewPage> {
  List<String> _extractLinks(String text) {
    RegExp urlRegex = RegExp(
      r'https?://(?:[-\w.])+(?:[:\d]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:#(?:\w)*)?)?',
      caseSensitive: false,
    );
    return urlRegex.allMatches(text).map((match) => match.group(0)!).toList();
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  Widget _buildMessageBubble(String message, bool isBot) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isBot ? Colors.white : Colors.blueGrey,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
            bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(0),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFormattedText(message, isBot ? Colors.black : Colors.white),
            if (isBot) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _showSources(context),
                icon: const Icon(Icons.library_books, size: 16),
                label: const Text('Sources'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                  minimumSize: const Size(80, 30),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedText(String text, Color color) {
    String cleanText = text
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('__', '')
        .replaceAll('#', '')
        .replaceAll('`', '');

    List<String> links = _extractLinks(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cleanText,
          style: TextStyle(color: color, fontSize: 16),
        ),
        if (links.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'References:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          ...links.map((link) => InkWell(
            onTap: () => _launchUrl(link),
            child: Text(
              link,
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          )),
        ],
      ],
    );
  }

  void _showSources(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Educational Sources',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('This AI uses information from reputable educational sources including:'),
              SizedBox(height: 8),
              Text('• Khan Academy, BBC Bitesize, NASA Education'),
              Text('• National Geographic Education, TED-Ed'),
              Text('• Wikipedia (Educational articles)'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.conversation['subject'] ?? 'Unknown Subject';
    final grade = widget.conversation['grade'] ?? 'Unknown Grade';
    final messages = List<Map<String, dynamic>>.from(widget.conversation['messages'] ?? []);
    final timestamp = DateTime.parse(widget.conversation['timestamp']);

    return Scaffold(
      appBar: AppBar(
        title: Text('$subject - Grade $grade'),
        backgroundColor: Colors.blueGrey,
        actions: [
          if (widget.onContinue != null)
            TextButton.icon(
              onPressed: widget.onContinue,
              icon: const Icon(Icons.chat, color: Colors.white),
              label: const Text('Continue', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF3E5F5),
              Color(0xFFE8F5E8),
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white.withValues(alpha: 0.9),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Started: ${_formatFullDate(timestamp)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${messages.length} messages',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(
                    message['message'] ?? '',
                    message['type'] == 'bot',
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
