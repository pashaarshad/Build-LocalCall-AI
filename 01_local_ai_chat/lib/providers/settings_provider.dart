import 'package:flutter/foundation.dart';
import '../models/llm_model_info.dart';
import '../services/groq_service.dart';
import '../services/llm_service.dart';
import '../services/storage_service.dart';

enum ConnectionStatus { unknown, testing, connected, failed }

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  late GroqService _groqService;

  late String _apiKey;
  late String _selectedModel;
  late String _systemPrompt;
  late double _temperature;

  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  String _statusMessage = 'Checking connection...';

  SettingsProvider(this._storage) {
    _apiKey = _storage.getApiKey();
    _selectedModel = _storage.getSelectedModel();
    if (_selectedModel.contains('0.5b') || _selectedModel.contains('1.5b') || _selectedModel == 'custom') {
      _selectedModel = 'qwen/qwen3.8-27b';
      _storage.setSelectedModel(_selectedModel);
    }
    _systemPrompt = _storage.getSystemPrompt();
    _temperature = _storage.getTemperature();

    _groqService = GroqService(apiKey: _apiKey);
    testConnection();
  }

  String get apiKey => _apiKey;
  String get selectedModel => _selectedModel;
  String get serverUrl => 'api.groq.com';
  String get systemPrompt => _systemPrompt;
  double get temperature => _temperature;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String get statusMessage => _statusMessage;
  GroqService get groqService => _groqService;
  LLMService get activeService => _groqService;

  LLMModelInfo get currentModelInfo => LLMModelInfo.findById(_selectedModel);

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    _groqService.apiKey = _apiKey;
    await _storage.setApiKey(_apiKey);
    notifyListeners();
    await testConnection();
  }

  Future<void> setSelectedModel(String model) async {
    _selectedModel = model;
    await _storage.setSelectedModel(model);
    notifyListeners();
  }

  Future<void> setSystemPrompt(String prompt) async {
    _systemPrompt = prompt;
    await _storage.setSystemPrompt(prompt);
    notifyListeners();
  }

  Future<void> setTemperature(double temp) async {
    _temperature = temp;
    await _storage.setTemperature(temp);
    notifyListeners();
  }

  Future<void> testConnection() async {
    _connectionStatus = ConnectionStatus.testing;
    _statusMessage = 'Connecting to Groq AI Cloud...';
    notifyListeners();

    try {
      final isOnline = await _groqService.checkConnection();
      if (isOnline) {
        _connectionStatus = ConnectionStatus.connected;
        _statusMessage = 'Connected • Ultra-Fast Speed (500+ tok/s)';
      } else {
        _connectionStatus = ConnectionStatus.failed;
        _statusMessage = 'Connection failed. Verify API Key.';
      }
    } catch (e) {
      _connectionStatus = ConnectionStatus.failed;
      _statusMessage = 'Error: $e';
    }
    notifyListeners();
  }
}
