import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_page.dart';
import 'chat_history_page.dart';
import 'theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Real Life Applications',
      theme: themeProvider.getThemeData(),
      home: const SubjectSelectionPage(title: 'Real Life Applications'),
    );
  }
}

class SubjectSelectionPage extends StatefulWidget {
  const SubjectSelectionPage({super.key, required this.title});

  final String title;

  @override
  State<SubjectSelectionPage> createState() => _SubjectSelectionPageState();
}



class AIChatPage extends StatefulWidget {
  final String subject;
  final String grade;
  final Map<String, dynamic>? existingConversation;

  const AIChatPage({
    super.key,
    required this.subject,
    required this.grade,
    this.existingConversation
  });

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _SubjectSelectionPageState extends State<SubjectSelectionPage> {
  String? selectedSubject;
  String? selectedGrade;
  List<String> applications = [];
  bool isLoadingApplications = false;
  bool _showSettingsPrompt = true;

  List<String> grades = ['5', '6', '7', '8', '9', '10', '11', '12', 'College'];
  Timer? _promptTimer;

  @override
  void initState() {
    super.initState();
    // Start timer to hide settings prompt after 10 seconds
    _promptTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _showSettingsPrompt = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _promptTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real Life Applications'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryPage()),
              );
            },
            tooltip: 'Chat History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              setState(() {
                _showSettingsPrompt = false;
              });
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.overlay,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.01),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.02),
                  Colors.transparent,
                ],
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                backgroundBlendMode: BlendMode.softLight,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    Colors.transparent,
                    Theme.of(context).cardColor.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  backgroundBlendMode: BlendMode.multiply,
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).dividerColor.withValues(alpha: 0.003),
                      Colors.transparent,
                    ],
                  ),
                ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.background,
                      Theme.of(context).colorScheme.background.withValues(alpha: 0.8),
                      Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                    ],
                  ),
                ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Explore how your classroom concepts apply to the real world!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (_showSettingsPrompt) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '📝 Please enter your Settings first by tapping the gear icon above to configure your AI provider and API key.',
                          style: TextStyle(
                            color: Colors.orange.shade800,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'Select a subject:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButtonFormField<String>(
                  value: selectedSubject,
                  hint: const Text('Choose a subject'),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: 'Math',
                      child: Text('Math'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Science',
                      child: Text('Science'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Physics',
                      child: Text('Physics'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Chemistry',
                      child: Text('Chemistry'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Biology',
                      child: Text('Biology'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Geography',
                      child: Text('Geography'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'History',
                      child: Text('History'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Environmental Science',
                      child: Text('Environmental Science'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Commerce',
                      child: Text('Commerce'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'Economics',
                      child: Text('Economics'),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSubject = newValue;
                      selectedGrade = null; // Reset grade when subject changes
                      applications = [];
                    });
                  },
                ),
              ),
              if (selectedSubject != null) ...[
                const SizedBox(height: 30),
                const Text(
                  'Select your grade level:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: selectedGrade,
                    hint: const Text('Choose your grade'),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                    items: grades.map((grade) {
                      return DropdownMenuItem<String>(
                        value: grade,
                        child: Text('Grade $grade'),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedGrade = newValue;
                        if (selectedSubject != null && selectedGrade != null) {
                          fetchApplications();
                        }
                      });
                    },
                  ),
                ),
              ],
              if (selectedSubject != null && selectedGrade != null) ...[
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    if (selectedSubject != null && selectedGrade != null) {
                      setState(() {
                        _showSettingsPrompt = false;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIChatPage(
                            subject: selectedSubject!,
                            grade: selectedGrade!,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Continue to AI Chat',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
              if (isLoadingApplications) ...[
                const SizedBox(height: 30),
                const Center(child: CircularProgressIndicator()),
              ],
              if (applications.isNotEmpty) ...[
                const SizedBox(height: 30),
                const Text(
                  'Real-World Applications:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            applications[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void fetchApplications() async {
    if (selectedSubject == null) return;

    setState(() {
      isLoadingApplications = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/applications/${Uri.encodeComponent(selectedSubject!)}'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          applications = List<String>.from(data['applications']);
        });
      } else {
        setState(() {
          applications = ['Error: Unable to fetch applications. Please try again.'];
        });
      }
    } catch (e) {
      // Don't show connection error if backend is not running - let user proceed without applications
      setState(() {
        applications = [];
      });
    } finally {
      setState(() {
        isLoadingApplications = false;
      });
    }
  }
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isTyping = false;
  Map<String, dynamic> _currentUsage = {'input_tokens': 0, 'output_tokens': 0, 'total_tokens': 0, 'cost': 0.0};

  @override
  void initState() {
    super.initState();
    if (widget.existingConversation != null) {
      _loadExistingConversation();
    } else {
      _addInitialMessage();
    }
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUsage = {
        'input_tokens': prefs.getInt('input_tokens') ?? 0,
        'output_tokens': prefs.getInt('output_tokens') ?? 0,
        'total_tokens': prefs.getInt('total_tokens') ?? 0,
        'cost': prefs.getDouble('usage_cost') ?? 0.0,
      };
    });
  }

  Future<void> _saveUsageData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('input_tokens', _currentUsage['input_tokens']);
    await prefs.setInt('output_tokens', _currentUsage['output_tokens']);
    await prefs.setInt('total_tokens', _currentUsage['total_tokens']);
    await prefs.setDouble('usage_cost', _currentUsage['cost']);
  }



  void _loadExistingConversation() {
    if (widget.existingConversation != null) {
      final messages = List<Map<String, dynamic>>.from(widget.existingConversation!['messages'] ?? []);
      setState(() {
        _messages.addAll(messages.map((msg) => Map<String, String>.from(msg)).toList());
      });
    }
  }

  void _addInitialMessage() {
    _messages.add({
      'type': 'bot',
      'message': 'Hi! I can help you understand how ${widget.subject} concepts apply to real life. What would you like to learn about?',
    });
    _saveConversation();
  }

  Future<void> _saveConversation() async {
    if (_messages.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final conversations = prefs.getStringList('chat_conversations') ?? [];

    // Create conversation object
    final conversation = {
      'id': '${widget.subject}_${widget.grade}_${DateTime.now().millisecondsSinceEpoch}',
      'subject': widget.subject,
      'grade': widget.grade,
      'timestamp': DateTime.now().toIso8601String(),
      'messages': _messages,
    };

    // Check if conversation already exists (update) or create new
    final existingIndex = conversations.indexWhere((conv) {
      final data = json.decode(conv);
      return data['subject'] == widget.subject && data['grade'] == widget.grade;
    });

    if (existingIndex >= 0) {
      conversations[existingIndex] = json.encode(conversation);
    } else {
      conversations.add(json.encode(conversation));
    }

    await prefs.setStringList('chat_conversations', conversations);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subject} - Grade ${widget.grade}'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatHistoryPage()),
              );
            },
            tooltip: 'Chat History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.transparent,
            backgroundBlendMode: BlendMode.overlay,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.008),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.01),
                Colors.transparent,
              ],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              backgroundBlendMode: BlendMode.softLight,
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context).dividerColor.withValues(alpha: 0.002),
                  Theme.of(context).cardColor.withValues(alpha: 0.01),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.3, 0.8, 1.0],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.background,
                    Theme.of(context).colorScheme.background.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.6),
                  ],
                ),
              ),
              child: Column(
          children: [
            // Credit usage info bar
            FutureBuilder<Map<String, dynamic>>(
              future: _getCurrentModelInfo(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final modelInfo = snapshot.data!;
                  final isFree = modelInfo['isFree'];
                  final price = modelInfo['price'];
                  final modelName = modelInfo['name'];

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.smart_toy, size: 16, color: Colors.blueGrey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using: $modelName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFree ? Colors.green.shade100 : Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isFree ? 'FREE' : '\$${price.toStringAsFixed(2)}/1k tokens',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isFree ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.bolt, size: 14, color: Colors.amber.shade600),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentUsage['total_tokens']} tokens used',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_currentUsage['cost'] > 0) ...[
                              Text(
                                ' • ',
                                style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                '\$${_currentUsage['cost'].toStringAsFixed(4)} cost',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message['message']!, message['type'] == 'bot');
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('AI is typing...', style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ask about ${widget.subject} applications...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: () => _sendMessage(_messageController.text),
                    backgroundColor: Colors.blueGrey,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isBot) {
    // Parse sources from the message
    final sourcesData = _parseSources(message);
    final contentWithoutSources = sourcesData['content'];
    final sources = sourcesData['sources'];

    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isBot ? Theme.of(context).colorScheme.surface : Theme.of(context).primaryColor,
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
            // Main content rendered as Markdown
            _buildMarkdownContent(contentWithoutSources, isBot ? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black : Colors.white),
            if (isBot && sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showSourcesDialog(sources),
                  icon: const Icon(Icons.library_books, size: 16),
                  label: Text('${sources.length} Source${sources.length > 1 ? "s" : ""}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade100,
                    foregroundColor: Colors.blue.shade800,
                    minimumSize: const Size(double.infinity, 35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _parseSources(String message) {
    // Split message at SOURCES section
    final sourcesIndex = message.indexOf('\nSOURCES:');
    if (sourcesIndex == -1) {
      return {'content': message, 'sources': []};
    }

    final content = message.substring(0, sourcesIndex).trim();
    final sourcesText = message.substring(sourcesIndex + 1);

    // Parse sources (format: number. [Name](URL) - description)
    final sourcesLines = sourcesText.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .skip(1) // Skip "SOURCES:" line
        .toList();

    final sources = <Map<String, String>>[];
    for (final line in sourcesLines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // Remove numbering (e.g., "1. ", "2. ")
      final lineWithoutNumber = trimmedLine.replaceFirst(RegExp(r'^\d+\.\s*'), '');

      // Parse link format [Name](URL) - description
      final linkMatch = RegExp(r'\[([^\]]+)\]\(([^)]+)\)(\s*-\s*(.+))?').firstMatch(lineWithoutNumber);
      if (linkMatch != null) {
        sources.add({
          'name': linkMatch.group(1)!,
          'url': linkMatch.group(2)!,
          'description': linkMatch.group(4)?.trim() ?? '',
        });
      }
    }

    return {'content': content, 'sources': sources};
  }

  Widget _buildMarkdownContent(String content, Color color) {
    return MarkdownBody(
      data: content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: TextStyle(color: color, fontSize: 16),
        strong: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
        em: TextStyle(color: color, fontStyle: FontStyle.italic, fontSize: 16),
        listBullet: TextStyle(color: color, fontSize: 16),
        listBulletPadding: const EdgeInsets.only(right: 8),
        orderedListAlign: WrapAlignment.start,
        // Basic code styling
        code: TextStyle(
          backgroundColor: Colors.grey.shade200,
          color: Colors.black87,
          fontSize: 14,
          fontFamily: 'Monaco',
        ),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          _launchUrl(href);
        }
      },
    );
  }

  void _showSourcesDialog(List<Map<String, String>> sources) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.library_books, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    Text(
                      'Sources (${sources.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sources.length,
                    itemBuilder: (context, index) {
                      final source = sources[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              source['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (source['description']?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 4),
                              Text(
                                source['description']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _launchUrl(source['url'] ?? ''),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.link,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      source['url'] ?? '',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 14,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $url')),
      );
    }
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'type': 'user', 'message': text});
      _isTyping = true;
    });

    _messageController.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('api_key') ?? '';
      final provider = prefs.getString('ai_provider') ?? 'OpenRouter';
      final model = prefs.getString('ai_model') ?? 'deepseek/deepseek-r1';

      // Get current model pricing
      final modelInfo = await _getCurrentModelInfo();
      final price = modelInfo['price'] as double;

      if (apiKey.isEmpty) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'type': 'bot',
            'message': 'Please configure your API key in Settings to use the AI chat feature. You can use OpenRouter (free), OpenAI, or Anthropic models.',
          });
        });
        return;
      }

      final response = await http.post(
        Uri.parse('http://localhost:5001/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
          'X-Provider': provider,
          'X-Model': model,
          'X-Timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'X-User-ID': 'flutter-app', // Simple user ID for demo
        },
        body: json.encode({
          'message': text,
          'subject': widget.subject,
          'grade': widget.grade,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isTyping = false;
          _messages.add({
            'type': 'bot',
            'message': data['response'] ?? 'Sorry, I couldn\'t generate a response right now.',
          });
        });

        // Update token usage if provided
        if (data.containsKey('usage') && data['usage'] != null) {
          final usage = data['usage'] as Map<String, dynamic>;
          setState(() {
            _currentUsage = {
              'input_tokens': (_currentUsage['input_tokens'] as int) + (usage['input_tokens'] as int? ?? 0),
              'output_tokens': (_currentUsage['output_tokens'] as int) + (usage['output_tokens'] as int? ?? 0),
              'total_tokens': (_currentUsage['total_tokens'] as int) + (usage['total_tokens'] as int? ?? 0),
              'cost': (_currentUsage['cost'] as double) + ((usage['total_tokens'] as int? ?? 0) / 1000.0 * price),
            };
          });
          await _saveUsageData();
        }

        // Save conversation after successful message exchange
        _saveConversation();
      } else {
        setState(() {
          _isTyping = false;
          _messages.add({
            'type': 'bot',
            'message': 'Sorry, I\'m having trouble connecting to the AI service. Please check your API key and connection.',
          });
        });
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'type': 'bot',
          'message': 'Connection error. Please make sure the backend server is running and you have a valid API key.',
        });
      });
    }
  }

  Future<Map<String, dynamic>> _getCurrentModelInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString('ai_provider') ?? 'OpenRouter';
    final modelName = prefs.getString('ai_model') ?? 'deepseek/deepseek-r1';

    // Define model pricing information
    final Map<String, Map<String, dynamic>> allModels = {
      'OpenRouter': {
        'deepseek/deepseek-r1': {'isFree': false, 'price': 1.30},
        'deepseek/deepseek-r1-0528-qwen3-8b:free': {'isFree': true, 'price': 0.0},
        'meta-llama/llama-3.2-3b-instruct:free': {'isFree': true, 'price': 0.0},
        'microsoft/wizardlm-2-8x22b': {'isFree': false, 'price': 1.00},
        'google/gemma-7b-it:free': {'isFree': true, 'price': 0.0},
        'huggingface/zephyr-7b-beta:free': {'isFree': true, 'price': 0.0},
        'microsoft/phi-3-mini-128k-instruct:free': {'isFree': true, 'price': 0.0},
        'mistralai/mistral-7b-instruct:free': {'isFree': true, 'price': 0.0},
      },
      'OpenAI': {
        'gpt-4': {'isFree': false, 'price': 30.00},
        'gpt-4-turbo-preview': {'isFree': false, 'price': 10.00},
        'gpt-3.5-turbo': {'isFree': false, 'price': 2.00},
      },
      'Anthropic': {
        'claude-3-opus-20240229': {'isFree': false, 'price': 15.00},
        'claude-3-sonnet-20240229': {'isFree': false, 'price': 3.00},
        'claude-3-haiku-20240307': {'isFree': false, 'price': 0.25},
      },
    };

    final modelInfo = allModels[provider]?[modelName] ?? {'isFree': false, 'price': 0.0};

    return {
      'name': modelName,
      'isFree': modelInfo['isFree'],
      'price': modelInfo['price'],
    };
  }


}
