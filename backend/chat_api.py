from flask import Flask, request, jsonify
import requests
from flask_cors import CORS
from data_storage import DataStorage

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize data storage
data_store = DataStorage()

# This will be set dynamically, but keeping a default for fallback
DEFAULT_OPENROUTER_API_KEY = "your_default_openrouter_api_key_here"  # Add your default key here

def get_api_key():
    """Get API key from request headers or use default"""
    api_key = request.headers.get('X-API-Key')
    if api_key and api_key != 'default':
        return api_key
    return DEFAULT_OPENROUTER_API_KEY

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.get_json()
        user_message = data.get('message', '')
        subject = data.get('subject', '')
        grade = data.get('grade', '')

        # Get settings from headers
        api_key = request.headers.get('X-API-Key', '')
        provider = request.headers.get('X-Provider', 'OpenRouter')
        model = request.headers.get('X-Model', 'deepseek/deepseek-r1')

        if not api_key:
            return jsonify({'error': 'API key is required. Please configure it in Settings.'}), 400

        # Enhanced context with resource access instructions
        context = f"""You are an educational AI tutor helping students understand real-life applications of {subject} concepts. The student is in grade {grade}.

FORMATTING INSTRUCTIONS:
- Use **bold text** for emphasis on key concepts
- Use *italic text* for important terms
- Use numbered lists when explaining steps or examples (1., 2., etc.)
- Use bullet points and nested lists for organizing information hierarchically
- **Use tables** for comparing data, showing examples, or organizing structured information
  * Tables help students visualize relationships and patterns
  * Example format:
    | Concept | Description | Real-World Example |
    |---------|-------------|-------------------|
    | Photosynthesis | Process where plants make food | Growing vegetables in a garden |
- Use `inline code` for technical terms, equations, or specific values
- Use code blocks with triple backticks (```) for:
  * Mathematical equations or formulas
  * Step-by-step algorithms
  * Data structures or models
- Structure your response with clear paragraphs and headings when needed
- Use horizontal rules (---) to separate major sections

RESPONSE STRUCTURE:
- Start with a clear, engaging explanation
- Provide examples with numbered steps when helpful
- End with practical applications

SOURCE REQUIREMENTS:
- ALWAYS include a SOURCES section at the END of your response
- Use this exact format for sources:

SOURCES:
1. [Source Name](URL) - Brief description of what was used from this source
2. [Source Name](URL) - Brief description...

AVAILABLE EDUCATIONAL RESOURCES (include at least 1-2 specific sources per response):
- Use ONLY the EXACT URLs from the official websites - DO NOT compose or modify URLs
- For Khan Academy: Use the complete URL exactly as it appears on their site (e.g., https://www.khanacademy.org/partner-content/amnh/earthquakes-and-volcanoes/plate-tectonics)
- For BBC Bitesize: Use complete URLs (e.g., https://www.bbc.co.uk/bitesize/guides/zscxn39/revision/3)
- For other sites: Use complete, specific URLs rather than just domain names
- Khan Academy (https://www.khanacademy.org) - use exact URLs from their content pages
- BBC Bitesize (https://www.bbc.co.uk/bitesize) - use exact URLs from their guides
- NASA Education (https://www.nasa.gov/learning-resources) - use complete NASA education resource URLs
- National Geographic Education (https://www.nationalgeographic.com/education) - use complete article URLs
- TED-Ed (https://ed.ted.com) - use complete lesson URLs
- Wikipedia (https://en.wikipedia.org) - use complete article URLs for educational content only
- Britannica (https://britannica.com) - use complete encyclopedia entry URLs
- Official government education sites (.gov, .edu domains) - use complete program/lesson URLs when available

IMPORTANT RESTRICTIONS:
- DO NOT include any references or links in the main response text
- Always put sources in the SOURCES section at the end
- DO NOT use or reference open forum websites like Reddit, Quora, or social media
- DO NOT use crowd-sourced content or discussion forums
- ONLY use reputable educational sources from the approved list

Keep your response focused on {subject} applications with clear formatting and proper source citations."""

        # Determine API endpoint and headers based on provider
        base_url, headers = _get_provider_config(provider, api_key)

        # Call the appropriate AI service
        response = requests.post(
            f'{base_url}/chat/completions',
            headers=headers,
            json={
                'model': model,
                'messages': [
                    {'role': 'system', 'content': context},
                    {'role': 'user', 'content': user_message}
                ],
                'temperature': 0.7,
            }
        )

        if response.status_code == 200:
            result = response.json()
            # Handle different response formats for different providers
            if provider == 'Anthropic':
                ai_message = result['content'][0]['text']
            else:
                ai_message = result['choices'][0]['message']['content']

            # Extract token usage information from response
            usage_info = {}
            if 'usage' in result:
                usage_data = result['usage']
                # Handle different provider response formats
                if provider == 'Anthropic':
                    # Anthropic typically uses 'input_tokens' and 'output_tokens'
                    input_tokens = usage_data.get('input_tokens', 0)
                    output_tokens = usage_data.get('output_tokens', 0)
                    total_tokens = input_tokens + output_tokens
                else:
                    # OpenAI/OpenRouter format
                    input_tokens = usage_data.get('prompt_tokens', 0)
                    output_tokens = usage_data.get('completion_tokens', 0)
                    total_tokens = usage_data.get('total_tokens', input_tokens + output_tokens)

                usage_info = {
                    'input_tokens': input_tokens,
                    'output_tokens': output_tokens,
                    'total_tokens': total_tokens,
                }

            # Automatically save chat history
            user_id = data_store.get_user_id_from_request(request)
            conversation_id = f"{subject}_{grade}_{int(data.get('timestamp', 0))}"

            # Build conversation data including this exchange
            conversation_data = {
                'subject': subject,
                'grade': grade,
                'timestamp': request.headers.get('X-Timestamp', data.get('timestamp')),
                'last_message': {
                    'user': user_message,
                    'bot': ai_message,
                    'timestamp': data.get('timestamp')
                }
            }

            # Try to save, but don't fail the response if storage fails
            try:
                data_store.save_chat_history(user_id, conversation_id, conversation_data)
            except Exception as storage_error:
                print(f"Warning: Chat history storage failed: {storage_error}")

            response_data = {'response': ai_message}
            if usage_info:
                response_data['usage'] = usage_info
            return jsonify(response_data)
        else:
            return jsonify({'error': f'Failed to get response from {provider} API (Status: {response.statusCode})'}), 500

    except Exception as e:
        return jsonify({'error': str(e)}), 500

def _get_provider_config(provider, api_key):
    """Get the base URL and headers for different AI providers"""
    if provider == 'OpenAI':
        return (
            'https://api.openai.com/v1',
            {
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            }
        )
    elif provider == 'Anthropic':
        return (
            'https://api.anthropic.com/v1',
            {
                'x-api-key': api_key,
                'anthropic-version': '2023-06-01',
                'Content-Type': 'application/json',
            }
        )
    elif provider == 'GoogleAI Studio':
        return (
            'https://generativelanguage.googleapis.com/v1beta',
            {
                'x-goog-api-key': api_key,
                'Content-Type': 'application/json',
            }
        )
    elif provider == 'LiteLLM':
        return (
            'http://localhost:4000',  # Default LiteLLM proxy server
            {
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
            }
        )
    else:  # OpenRouter (default)
        return (
            'https://openrouter.ai/api/v1',
            {
                'Authorization': f'Bearer {api_key}',
                'Content-Type': 'application/json',
                'HTTP-Referer': 'flutter-app',
                'X-Title': 'Real Life Applications App',
            }
        )

@app.route('/api/chat/completion', methods=['POST'])
def chat_completion():
    """Alternative endpoint for completion-style responses"""
    try:
        data = request.get_json()
        prompt = data.get('prompt', '')
        subject = data.get('subject', '')
        grade = data.get('grade', '')

        context = f"You are helping a grade {grade} student understand how {subject} applies to real life. Explain clearly and give practical examples."

        # Call OpenAI API with completion
        response = requests.post(
            'https://api.openai.com/v1/completions',
            headers={
                'Authorization': f'Bearer {OPENAI_API_KEY}',
                'Content-Type': 'application/json',
            },
            json={
                'model': 'text-davinci-003',
                'prompt': f"{context}\n\nStudent: {prompt}\n\nTeacher:",
                'max_tokens': 500,
                'temperature': 0.7,
            }
        )

        if response.status_code == 200:
            result = response.json()
            ai_message = result['choices'][0]['text'].strip()
            return jsonify({'response': ai_message})
        else:
            return jsonify({'error': 'Failed to get response from AI service'}), 500

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# API Key Management Endpoints
@app.route('/api/keys', methods=['POST'])
def save_api_key():
    """Save an API key with metadata for a user"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        data = request.get_json()

        if not isinstance(data, dict):
            return jsonify({'error': 'Invalid JSON data'}), 400

        key_name = data.get('key_name', 'default')
        provider = data.get('provider')
        api_key = data.get('api_key')
        credit_limit = data.get('credit_limit')

        if not provider or not api_key:
            return jsonify({'error': 'Provider and API key are required'}), 400

        success = data_store.save_api_key(user_id, key_name, provider, api_key, credit_limit)
        if success:
            return jsonify({'message': 'API key saved successfully', 'unique_key': f"{provider}_{key_name}"})
        else:
            return jsonify({'error': 'Failed to save API key'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/keys', methods=['GET'])
def get_api_keys():
    """Get all API keys for the current user"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        api_keys = data_store.get_api_keys_formatted(user_id)
        return jsonify({'api_keys': api_keys})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/keys/<provider>', methods=['DELETE'])
def delete_api_key(provider):
    """Delete an API key for a specific provider"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        success = data_store.delete_api_key(user_id, provider)
        if success:
            return jsonify({'message': 'API key deleted successfully'})
        else:
            return jsonify({'error': 'API key not found or failed to delete'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# Chat History Management Endpoints
@app.route('/api/history', methods=['POST'])
def save_chat_history():
    """Save or update a chat conversation"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        data = request.get_json()

        conversation_id = data.get('conversation_id')
        conversation_data = data.get('conversation_data', {})

        if not conversation_id:
            return jsonify({'error': 'Conversation ID is required'}), 400

        success = data_store.save_chat_history(user_id, conversation_id, conversation_data)
        if success:
            return jsonify({'message': 'Chat history saved successfully'})
        else:
            return jsonify({'error': 'Failed to save chat history'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/history', methods=['GET'])
def get_chat_history():
    """Get all chat history for the current user"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        history_data = data_store.get_chat_history(user_id)
        return jsonify(history_data)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/history/<conversation_id>', methods=['GET'])
def get_specific_conversation(conversation_id):
    """Get a specific conversation by ID"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        conversation = data_store.get_chat_history(user_id, conversation_id)
        if conversation:
            return jsonify(conversation)
        else:
            return jsonify({'error': 'Conversation not found'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/history/<conversation_id>', methods=['DELETE'])
def delete_conversation(conversation_id):
    """Delete a specific conversation"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        success = data_store.delete_chat_history(user_id, conversation_id)
        if success:
            return jsonify({'message': 'Conversation deleted successfully'})
        else:
            return jsonify({'error': 'Conversation not found or failed to delete'}), 404
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/history', methods=['DELETE'])
def clear_chat_history():
    """Clear all chat history for the current user"""
    try:
        user_id = data_store.get_user_id_from_request(request)
        success = data_store.clear_all_chat_history(user_id)
        if success:
            return jsonify({'message': 'All chat history cleared successfully'})
        else:
            return jsonify({'error': 'Failed to clear chat history'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)
