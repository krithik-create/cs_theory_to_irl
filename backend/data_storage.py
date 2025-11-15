"""
Data persistence layer for the Real Life Applications backend.
Handles storage of API keys and chat history using JSON files.
"""

import json
import os
import threading
from datetime import datetime
from typing import Dict, List, Optional, Any

class DataStorage:
    def __init__(self, data_dir: str = 'data'):
        self.data_dir = data_dir
        self._lock = threading.Lock()
        self._ensure_data_dir()

        # File paths
        self.api_keys_file = os.path.join(data_dir, 'api_keys.json')
        self.chat_history_file = os.path.join(data_dir, 'chat_history.json')

        # Initialize data files if they don't exist
        self._init_data_files()

    def _ensure_data_dir(self):
        """Ensure the data directory exists"""
        if not os.path.exists(self.data_dir):
            os.makedirs(self.data_dir)

    def _init_data_files(self):
        """Initialize data files with empty structures if they don't exist"""
        # API keys file
        if not os.path.exists(self.api_keys_file):
            with open(self.api_keys_file, 'w') as f:
                json.dump({}, f)

        # Chat history file
        if not os.path.exists(self.chat_history_file):
            with open(self.chat_history_file, 'w') as f:
                json.dump({}, f)

    def _load_json_file(self, file_path: str) -> Dict[str, Any]:
        """Safely load JSON data from file"""
        try:
            with open(file_path, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return {}

    def _save_json_file(self, file_path: str, data: Dict[str, Any]):
        """Safely save JSON data to file"""
        with self._lock:
            with open(file_path, 'w') as f:
                json.dump(data, f, indent=2, default=str)

    # API Key Management
    def save_api_key(self, user_id: str, key_name: str, provider: str, api_key: str, credit_limit: Optional[float] = None) -> bool:
        """Save an API key with metadata for a user"""
        try:
            data = self._load_json_file(self.api_keys_file)

            if user_id not in data:
                data[user_id] = {}

            # Create a unique key using provider + key_name
            unique_key = f"{provider}_{key_name}"

            data[user_id][unique_key] = {
                'key_name': key_name,
                'provider': provider,
                'api_key': api_key,
                'credit_limit': credit_limit,
                'updated_at': datetime.now().isoformat()
            }

            self._save_json_file(self.api_keys_file, data)
            return True
        except Exception as e:
            print(f"Error saving API key: {e}")
            return False

    def save_api_key_legacy(self, user_id: str, provider: str, api_key: str) -> bool:
        """Legacy method for backward compatibility - saves with 'default' key name"""
        return self.save_api_key(user_id, 'default', provider, api_key)

    def get_api_key(self, user_id: str, provider: str) -> Optional[str]:
        """Get an API key for a user and provider"""
        try:
            data = self._load_json_file(self.api_keys_file)
            return data.get(user_id, {}).get(provider, {}).get('api_key')
        except Exception as e:
            print(f"Error retrieving API key: {e}")
            return None

    def get_all_api_keys(self, user_id: str) -> Dict[str, Any]:
        """Get all API keys for a user"""
        try:
            data = self._load_json_file(self.api_keys_file)
            return data.get(user_id, {})
        except Exception as e:
            print(f"Error retrieving API keys: {e}")
            return {}

    def get_api_keys_formatted(self, user_id: str) -> List[Dict[str, Any]]:
        """Get all API keys for a user formatted as a list with metadata"""
        try:
            data = self._load_json_file(self.api_keys_file)
            user_keys = data.get(user_id, {})

            formatted_keys = []
            for unique_key, key_data in user_keys.items():
                formatted_keys.append({
                    'unique_key': unique_key,
                    'key_name': key_data.get('key_name', 'Unknown'),
                    'provider': key_data.get('provider', 'Unknown'),
                    'credit_limit': key_data.get('credit_limit'),
                    'updated_at': key_data.get('updated_at'),
                })

            # Sort by provider and then by key name
            formatted_keys.sort(key=lambda x: (x['provider'], x['key_name']))
            return formatted_keys
        except Exception as e:
            print(f"Error retrieving formatted API keys: {e}")
            return []

    def get_api_key_by_name(self, user_id: str, key_name: str, provider: str) -> Optional[Dict[str, Any]]:
        """Get a specific API key by name and provider"""
        try:
            data = self._load_json_file(self.api_keys_file)
            user_keys = data.get(user_id, {})
            unique_key = f"{provider}_{key_name}"

            if unique_key in user_keys:
                key_data = user_keys[unique_key].copy()
                key_data['unique_key'] = unique_key
                return key_data

            return None
        except Exception as e:
            print(f"Error retrieving API key by name: {e}")
            return None

    def delete_api_key(self, user_id: str, provider: str) -> bool:
        """Delete an API key for a user and provider"""
        try:
            data = self._load_json_file(self.api_keys_file)

            if user_id in data and provider in data[user_id]:
                del data[user_id][provider]

                # Remove user entry if no keys left
                if not data[user_id]:
                    del data[user_id]

                self._save_json_file(self.api_keys_file, data)
                return True
            return False
        except Exception as e:
            print(f"Error deleting API key: {e}")
            return False

    # Chat History Management
    def save_chat_history(self, user_id: str, conversation_id: str, conversation_data: Dict[str, Any]) -> bool:
        """Save a chat conversation for a user"""
        try:
            data = self._load_json_file(self.chat_history_file)

            if user_id not in data:
                data[user_id] = {}

            # Add/update metadata
            if 'timestamp' not in conversation_data:
                conversation_data['timestamp'] = datetime.now().isoformat()

            conversation_data['conversation_id'] = conversation_id

            # Store by conversation ID
            data[user_id][conversation_id] = conversation_data

            self._save_json_file(self.chat_history_file, data)
            return True
        except Exception as e:
            print(f"Error saving chat history: {e}")
            return False

    def get_chat_history(self, user_id: str, conversation_id: Optional[str] = None) -> Dict[str, Any]:
        """Get chat history for a user (all conversations or specific one)"""
        try:
            data = self._load_json_file(self.chat_history_file)
            user_data = data.get(user_id, {})

            if conversation_id:
                return user_data.get(conversation_id, {})
            else:
                # Return all conversations sorted by timestamp (newest first)
                conversations = list(user_data.values())
                conversations.sort(key=lambda x: x.get('timestamp', ''), reverse=True)
                return {'conversations': conversations}
        except Exception as e:
            print(f"Error retrieving chat history: {e}")
            return {}

    def delete_chat_history(self, user_id: str, conversation_id: str) -> bool:
        """Delete a specific chat conversation"""
        try:
            data = self._load_json_file(self.chat_history_file)

            if user_id in data and conversation_id in data[user_id]:
                del data[user_id][conversation_id]

                self._save_json_file(self.chat_history_file, data)
                return True
            return False
        except Exception as e:
            print(f"Error deleting chat history: {e}")
            return False

    def clear_all_chat_history(self, user_id: str) -> bool:
        """Clear all chat history for a user"""
        try:
            data = self._load_json_file(self.chat_history_file)

            if user_id in data:
                del data[user_id]
                self._save_json_file(self.chat_history_file, data)
                return True
            return False
        except Exception as e:
            print(f"Error clearing chat history: {e}")
            return False

    # Utility method to get a user ID (for now using a simple identifier)
    def get_user_id_from_request(self, request) -> str:
        """Extract or generate a user ID from the request"""
        # For now, use a simple approach - this could be enhanced with proper authentication
        # We could use IP address, or accept a user_id header
        user_id = request.headers.get('X-User-ID', request.remote_addr)
        return user_id or 'anonymous'
