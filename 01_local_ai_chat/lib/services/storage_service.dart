import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_session.dart';

class StorageService {
  static const String _keySessions = 'chat_sessions_v1';
  static const String _keyActiveSessionId = 'active_session_id';
  static const String _keyServerUrl = 'server_url';
  static const String _keySelectedModel = 'selected_model';
  static const String _keySystemPrompt = 'system_prompt';
  static const String _keyTemperature = 'temperature';
  static const String _keyApiKey = 'api_key';
  static const String _keyInferenceMode = 'inference_mode';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- Sessions Persistence ---

  Future<void> saveSessions(List<ChatSession> sessions) async {
    final listJson = sessions.map((s) => s.toJson()).toList();
    await _prefs.setString(_keySessions, jsonEncode(listJson));
  }

  List<ChatSession> loadSessions() {
    final raw = _prefs.getString(_keySessions);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  String? getActiveSessionId() {
    return _prefs.getString(_keyActiveSessionId);
  }

  Future<void> setActiveSessionId(String id) async {
    await _prefs.setString(_keyActiveSessionId, id);
  }

  // --- Settings Persistence ---

  String getServerUrl() {
    return _prefs.getString(_keyServerUrl) ?? 'http://127.0.0.1:11434';
  }

  Future<void> setServerUrl(String url) async {
    await _prefs.setString(_keyServerUrl, url);
  }

  String getSelectedModel() {
    return _prefs.getString(_keySelectedModel) ?? 'qwen2.5:0.5b';
  }

  Future<void> setSelectedModel(String model) async {
    await _prefs.setString(_keySelectedModel, model);
  }

  String getSystemPrompt() {
    return _prefs.getString(_keySystemPrompt) ??
        'You are LocalCall Assistant, a helpful, polite, and intelligent AI companion designed for mobile devices. Respond clearly, concisely, and accurately.';
  }

  Future<void> setSystemPrompt(String prompt) async {
    await _prefs.setString(_keySystemPrompt, prompt);
  }

  double getTemperature() {
    return _prefs.getDouble(_keyTemperature) ?? 0.7;
  }

  Future<void> setTemperature(double temp) async {
    await _prefs.setDouble(_keyTemperature, temp);
  }

  String getApiKey() {
    return _prefs.getString(_keyApiKey) ??
        '';
  }

  Future<void> setApiKey(String key) async {
    await _prefs.setString(_keyApiKey, key);
  }

  String getInferenceMode() {
    return _prefs.getString(_keyInferenceMode) ?? 'groqCloud';
  }

  Future<void> setInferenceMode(String mode) async {
    await _prefs.setString(_keyInferenceMode, mode);
  }
}

