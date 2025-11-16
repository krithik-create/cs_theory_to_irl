import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

// Constants
const List<String> kAvailableProviders = ['OpenRouter', 'OpenAI', 'Anthropic', 'GoogleAI Studio', 'LiteLLM'];
const List<String> kAvailableModels = [
  'deepseek/deepseek-r1-0528-qwen3-8b:free',
  'meta-llama/llama-3.2-3b-instruct:free',
  'google/gemma-7b-it:free',
  'huggingface/zephyr-7b-beta:free',
  'microsoft/phi-3-mini-128k-instruct:free',
  'mistralai/mistral-7b-instruct:free',
];

const String kDefaultModel = 'deepseek/deepseek-r1-0528-qwen3-8b:free';
const String kDefaultProvider = 'OpenRouter';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedTheme = 'light';
  String _selectedProvider = kDefaultProvider;
  String _selectedModel = kDefaultModel;

  // API Key management state
  List<Map<String, dynamic>> _savedApiKeys = [];
  String? _selectedApiKeyUniqueKey;
  late bool _isLoadingKeys;

  // Missing state variables for UI functionality
  late String _testResult;
  late bool _isTestingConnection;
  late TextEditingController _apiKeyController;
  late bool _useCustomModel;
  late TextEditingController _customModelController;

  @override
  void initState() {
    super.initState();
    // Initialize state variables
    _apiKeyController = TextEditingController();
    _customModelController = TextEditingController();
    _savedApiKeys = [];
    _isLoadingKeys = false;
    _testResult = '';
    _isTestingConnection = false;
    _useCustomModel = false;
    _loadSettings();
    _loadSavedApiKeys();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    // Load theme and other settings
    setState(() {
      _selectedProvider = prefs.getString('ai_provider') ?? kDefaultProvider;
      _selectedModel = prefs.getString('ai_model') ?? kDefaultModel;
      _useCustomModel = prefs.getBool('use_custom_model') ?? false;
      _customModelController.text = prefs.getString('custom_model') ?? '';
      _selectedTheme = themeProvider.currentTheme.name;
    });

    // First load saved API keys from backend
    await _loadSavedApiKeys();

    // Then load the last selected API key
    final selectedApiKeyUniqueKey = prefs.getString('selected_api_key_unique_key');
    if (selectedApiKeyUniqueKey != null && _savedApiKeys.isNotEmpty) {
      // Check if the saved key still exists in our loaded keys
      final keyExists = _savedApiKeys.any((key) => key['unique_key'] == selectedApiKeyUniqueKey);
      if (keyExists) {
        final selectedKey = _savedApiKeys.firstWhere(
          (key) => key['unique_key'] == selectedApiKeyUniqueKey,
          orElse: () => <String, dynamic>{},
        );

        if (selectedKey.isNotEmpty) {
          setState(() {
            _selectedApiKeyUniqueKey = selectedApiKeyUniqueKey;
            _selectedProvider = selectedKey['provider'] ?? kDefaultProvider;
            _apiKeyController.text = selectedKey['api_key'] ?? '';
          });
        }
      } else {
        // Reset to null if the saved key no longer exists
        setState(() {
          _selectedApiKeyUniqueKey = null;
          _selectedProvider = kDefaultProvider;
          _apiKeyController.text = '';
        });
        // Clear the invalid saved key
        await prefs.remove('selected_api_key_unique_key');
      }
    }

    // Fallback to legacy loading if no selected key
    if (_selectedApiKeyUniqueKey == null) {
      final localApiKey = prefs.getString('api_key');
      try {
        final backendApiKey = await _loadApiKeyFromBackend(_selectedProvider);
        if (backendApiKey != null && backendApiKey.isNotEmpty) {
          setState(() {
            _apiKeyController.text = backendApiKey;
          });
          await prefs.setString('api_key', backendApiKey);
        } else if (localApiKey != null && localApiKey.isNotEmpty) {
          setState(() {
            _apiKeyController.text = localApiKey;
          });
          await _saveApiKeyToBackend(localApiKey, _selectedProvider);
        }
      } catch (e) {
        setState(() {
          _apiKeyController.text = localApiKey ?? '';
        });
        print('Failed to load API key from backend: $e');
      }
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _apiKeyController.text);
    await prefs.setString('ai_provider', _selectedProvider);
    await prefs.setString('ai_model', _useCustomModel ? _customModelController.text : _selectedModel);
    await prefs.setBool('use_custom_model', _useCustomModel);
    await prefs.setString('custom_model', _customModelController.text);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  Future<void> _saveApiKeyToBackend(String apiKey, String provider) async {
    try {
      const String backendUrl = 'http://localhost:5001'; // Adjust if your backend is running on a different port/host

      final response = await http.post(
        Uri.parse('$backendUrl/api/keys'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'provider': provider,
          'api_key': apiKey,
        }),
      );

      if (response.statusCode == 200) {
        print('API key saved to backend successfully');
      } else {
        throw Exception('Failed to save API key to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error saving API key to backend: $e');
      rethrow;
    }
  }

  Future<String?> _loadApiKeyFromBackend(String provider) async {
    try {
      const String backendUrl = 'http://localhost:5001'; // Adjust if your backend is running on a different port/host

      final response = await http.get(Uri.parse('$backendUrl/api/keys'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiKeys = data['api_keys'] as Map<String, dynamic>?;
        if (apiKeys != null && apiKeys.containsKey(provider)) {
          return apiKeys[provider]['api_key'] as String?;
        }
        return null;
      } else {
        throw Exception('Failed to load API keys from backend: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading API key from backend: $e');
      rethrow;
    }
  }

  Future<void> _testConnection() async {
    if (_apiKeyController.text.isEmpty) {
      setState(() {
        _testResult = 'Please enter an API key first';
      });
      return;
    }

    setState(() {
      _isTestingConnection = true;
      _testResult = '';
    });

    try {
      // String modelToTest = _useCustomModel ? _customModelController.text : _selectedModel;
      String baseUrl = _getBaseUrl();

      // Use a simple model for testing to avoid issues
      String testModel = 'deepseek/deepseek-r1-0528-qwen3-8b:free';

      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: _getHeaders(),
        body: json.encode({
          'model': testModel,
          'messages': [
            {'role': 'user', 'content': 'Hello! This is a test message. Please respond with "Test successful" if you can read this.'}
          ],
          'max_tokens': 50,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['choices'] != null && data['choices'].isNotEmpty) {
          setState(() {
            _testResult = '✅ Connection successful! AI model is working.';
          });
        } else {
          setState(() {
            _testResult = '❌ Unexpected response format';
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _testResult = '❌ Invalid API key. Please check your key.';
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _testResult = '❌ Rate limited. Please try again later.';
        });
      } else {
        setState(() {
          _testResult = '❌ Connection failed (Status: ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ Network error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isTestingConnection = false;
      });
    }
  }

  String _getBaseUrl() {
    switch (_selectedProvider) {
      case 'OpenAI':
        return 'https://api.openai.com/v1';
      case 'Anthropic':
        return 'https://api.anthropic.com/v1';
      default:
        return 'https://openrouter.ai/api/v1';
    }
  }

  Map<String, String> _getHeaders() {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    switch (_selectedProvider) {
      case 'OpenAI':
        headers['Authorization'] = 'Bearer ${_apiKeyController.text}';
        break;
      case 'Anthropic':
        headers['x-api-key'] = _apiKeyController.text;
        headers['anthropic-version'] = '2023-06-01';
        break;
      default: // OpenRouter
        headers['Authorization'] = 'Bearer ${_apiKeyController.text}';
        headers['HTTP-Referer'] = 'flutter-app';
        headers['X-Title'] = 'Real Life Applications App';
        break;
    }

    return headers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.settings,
                      size: 40,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'App Settings',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Customize your app experience with themes and AI model preferences.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Theme Selection
              const Text(
                'App Theme:',
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
                  value: _selectedTheme,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: [
                    DropdownMenuItem<String>(
                      value: 'light',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.blue.shade50,
                              Colors.grey.shade100,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blueGrey.shade200, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blueGrey, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Light',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'dark',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey.shade800,
                              Colors.black54,
                              Colors.grey.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade600, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade600,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.grey.shade400, width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Dark'),
                          ],
                        ),
                      ),
                    ),
                    DropdownMenuItem<String>(
                      value: 'midnight_grey',
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF2C3E50),
                              const Color(0xFF34495E),
                              const Color(0xFF2C3E50).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF34495E), width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: const Color(0xFF34495E),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF2C3E50), width: 2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text('Midnight Grey'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedTheme = newValue;
                      });
                      // Update the app's theme
                      Provider.of<ThemeProvider>(context, listen: false).setTheme(newValue);
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              // AI Provider Selection
              const Text(
                'AI Provider:',
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
                  value: _selectedProvider,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: kAvailableProviders.map((provider) {
                    return DropdownMenuItem<String>(
                      value: provider,
                      child: Text(provider),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedProvider = newValue;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // API Key Management Section
              Row(
                children: [
                  const Text(
                    'Add API key',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _showApiKeyHelp,
                    icon: const Icon(
                      Icons.help_outline,
                      size: 20,
                      color: Colors.blue,
                    ),
                    tooltip: 'How to get API Key',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: InkWell(
                  onTap: _showAddApiKeyDialog,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.add, color: Colors.blue),
                        SizedBox(width: 12),
                        Text(
                          'Add new API key',
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // API Key Selection Dropdown
              const Text(
                'Select API Key:',
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
                child: _isLoadingKeys
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedApiKeyUniqueKey,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                        hint: const Text('Select an API key'),
                        items: [
                          // Add a "None" option to handle invalid selections
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Select an API key'),
                          ),
                          // Filter and add valid API keys
                          ..._savedApiKeys.where((key) {
                            // Filter out invalid or incomplete key entries
                            final keyName = key['key_name'] as String?;
                            final provider = key['provider'] as String?;
                            final uniqueKey = key['unique_key'] as String?;
                            return keyName != null && keyName.isNotEmpty &&
                                   provider != null && provider.isNotEmpty &&
                                   uniqueKey != null && uniqueKey.isNotEmpty;
                          }).map((key) {
                            final keyName = key['key_name'] as String?;
                            final provider = key['provider'] as String?;
                            final uniqueKey = key['unique_key'] as String?;

                            return DropdownMenuItem<String>(
                              value: uniqueKey,
                              child: Text('$keyName ($provider)'),
                            );
                          }).toList(),
                        ],
                        onChanged: (String? newValue) async {
                          setState(() {
                            _selectedApiKeyUniqueKey = newValue;
                          });

                          if (newValue != null && newValue.isNotEmpty) {
                            // Load the actual API key for the selected key
                            final selectedKey = _savedApiKeys.firstWhere(
                              (key) => key['unique_key'] == newValue,
                              orElse: () => <String, dynamic>{},
                            );

                            if (selectedKey.isNotEmpty) {
                              setState(() {
                                _selectedProvider = selectedKey['provider'] as String? ?? kDefaultProvider;
                                _apiKeyController.text = selectedKey['api_key'] ?? '';
                              });

                              // Save to local storage as the current selection
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('selected_api_key_unique_key', newValue);
                              await prefs.setString('ai_provider', _selectedProvider);
                            }
                          } else {
                            // Handle case when no key is selected
                            setState(() {
                              _selectedProvider = kDefaultProvider;
                              _apiKeyController.text = '';
                            });
                          }
                        },
                      ),
              ),

              const SizedBox(height: 20),

              // Custom Model Toggle
              Row(
                children: [
                  const Text(
                    'Use Custom Model:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Switch(
                    value: _useCustomModel,
                    onChanged: (bool value) {
                      setState(() {
                        _useCustomModel = value;
                      });
                    },
                  ),
                ],
              ),

              if (_useCustomModel) ...[
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: TextField(
                    controller: _customModelController,
                    decoration: const InputDecoration(
                      hintText: 'Enter custom model name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Test Connection Section
              const Text(
                'Test Connection:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isTestingConnection ? null : _testConnection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isTestingConnection
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Test Connection',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              if (_testResult.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _testResult.contains('✅')
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _testResult.contains('✅')
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    _testResult,
                    style: TextStyle(
                      color: _testResult.contains('✅')
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Model Selection
              const Text(
                'AI Model:',
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
                  value: _selectedModel,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                  items: kAvailableModels.map((model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(model),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedModel = newValue;
                      });
                    }
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Save Settings',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // About Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  children: [
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Educational AI Chat Application\nVersion 1.0.0\n\nBuilt with Flutter for students and teachers.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  Widget _buildProviderInfo(String name, String url, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$name: ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              InkWell(
                onTap: () => _launchUrl(url),
                child: Text(
                  'Get API Key',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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

  Future<void> _loadSavedApiKeys() async {
    try {
      const String backendUrl = 'http://localhost:5001';
      final response = await http.get(Uri.parse('$backendUrl/api/keys'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final apiKeys = data['api_keys'] as List<dynamic>? ?? [];

        setState(() {
          _savedApiKeys = apiKeys.map((key) => Map<String, dynamic>.from(key)).toList();
          _isLoadingKeys = false;
        });
      } else {
        setState(() {
          _isLoadingKeys = false;
        });
        print('Failed to load saved API keys: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingKeys = false;
      });
      print('Error loading saved API keys: $e');
    }
  }

  void _showAddApiKeyDialog() {
    String selectedProvider = kAvailableProviders[0];
    final keyNameController = TextEditingController();
    final creditLimitController = TextEditingController();
    final apiKeyController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add API Key'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Provider Selection
                DropdownButtonFormField<String>(
                  value: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Provider',
                    border: OutlineInputBorder(),
                  ),
                  items: kAvailableProviders.map((provider) {
                    return DropdownMenuItem<String>(
                      value: provider,
                      child: Text(provider),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedProvider = newValue;
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Key Name
                TextField(
                  controller: keyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Key Name',
                    hintText: 'e.g., Personal Key, Work Key',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // API Key
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),

                // Credit Limit (optional)
                TextField(
                  controller: creditLimitController,
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit (optional)',
                    hintText: 'e.g., 100',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final keyName = keyNameController.text.trim();
                final apiKey = apiKeyController.text.trim();
                final creditLimit = double.tryParse(creditLimitController.text.trim()) ?? 0.0;

                if (keyName.isEmpty || apiKey.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key name and API key are required')),
                  );
                  return;
                }

                try {
                  const String backendUrl = 'http://localhost:5001';
                  final response = await http.post(
                    Uri.parse('$backendUrl/api/keys'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({
                      'key_name': keyName,
                      'provider': selectedProvider,
                      'api_key': apiKey,
                      'credit_limit': creditLimit > 0 ? creditLimit : null,
                    }),
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    await _loadSavedApiKeys();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('API key saved successfully!')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save API key')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving API key: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showApiKeyHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('API Key Help'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To get an API key for ${_selectedProvider}:'),
              const SizedBox(height: 8),
              Text('1. Visit the provider\'s website'),
              Text('2. Sign up for an account'),
              Text('3. Navigate to API keys or settings'),
              Text('4. Create a new API key'),
              Text('5. Copy and paste it here'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
