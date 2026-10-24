import 'package:flutter/foundation.dart';
import '../models/llm_model_info.dart';
import '../services/ollama_service.dart';
import '../services/storage_service.dart';

enum ConnectionStatus { unknown, testing, connected, failed }

class SettingsProvider with ChangeNotifier {
  final StorageService _storage;
  final OllamaService _ollamaService;

  late String _serverUrl;
  late String _selectedModel;
  late String _systemPrompt;
  late double _temperature;

  ConnectionStatus _connectionStatus = ConnectionStatus.unknown;
  String _statusMessage = 'Not tested';
  List<String> _availableServerModels = [];

  SettingsProvider(this._storage, this._ollamaService) {
    _serverUrl = _storage.getServerUrl();
    _selectedModel = _storage.getSelectedModel();
    _systemPrompt = _storage.getSystemPrompt();
    _temperature = _storage.getTemperature();
    _ollamaService.baseUrl = _serverUrl;
    testConnection();
  }

  String get serverUrl => _serverUrl;
  String get selectedModel => _selectedModel;
  String get systemPrompt => _systemPrompt;
  double get temperature => _temperature;
  ConnectionStatus get connectionStatus => _connectionStatus;
  String get statusMessage => _statusMessage;
  List<String> get availableServerModels => _availableServerModels;
  OllamaService get ollamaService => _ollamaService;

  LLMModelInfo get currentModelInfo => LLMModelInfo.findById(_selectedModel);

  Future<void> setServerUrl(String url) async {
    _serverUrl = url;
    _ollamaService.baseUrl = url;
    await _storage.setServerUrl(url);
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
    _statusMessage = 'Connecting to $_serverUrl...';
    notifyListeners();

    try {
      final isOnline = await _ollamaService.checkConnection();
      if (isOnline) {
        _connectionStatus = ConnectionStatus.connected;
        _statusMessage = 'Connected to Ollama';
        _availableServerModels = await _ollamaService.listAvailableModels();
      } else {
        _connectionStatus = ConnectionStatus.failed;
        _statusMessage = 'Unreachable host';
      }
    } catch (e) {
      _connectionStatus = ConnectionStatus.failed;
      _statusMessage = 'Connection error: ${e.toString()}';
    }
    notifyListeners();
  }
}
