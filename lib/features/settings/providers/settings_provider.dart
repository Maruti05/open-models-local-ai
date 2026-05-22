import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final double temperature;
  final double topP;
  final int topK;
  final int maxTokens;
  final String systemPrompt;
  final bool showThinking;
  final bool showReasoning;

  SettingsState({
    this.temperature = 0.7,
    this.topP = 0.9,
    this.topK = 40,
    this.maxTokens = 512,
    this.systemPrompt =
        'You are an advanced, helpful offline AI assistant running locally on the user\'s mobile hardware.',
    this.showThinking = true,
    this.showReasoning = true,
  });

  SettingsState copyWith({
    double? temperature,
    double? topP,
    int? topK,
    int? maxTokens,
    String? systemPrompt,
    bool? showThinking,
    bool? showReasoning,
  }) {
    return SettingsState(
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      maxTokens: maxTokens ?? this.maxTokens,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      showThinking: showThinking ?? this.showThinking,
      showReasoning: showReasoning ?? this.showReasoning,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'topP': topP,
      'topK': topK,
      'maxTokens': maxTokens,
      'systemPrompt': systemPrompt,
      'showThinking': showThinking,
      'showReasoning': showReasoning,
    };
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SharedPreferences? _prefs;

  SettingsNotifier() : super(SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      temperature: _prefs?.getDouble('temperature') ?? 0.7,
      topP: _prefs?.getDouble('topP') ?? 0.9,
      topK: _prefs?.getInt('topK') ?? 40,
      maxTokens: _prefs?.getInt('maxTokens') ?? 512,
      systemPrompt: _prefs?.getString('systemPrompt') ??
          'You are an advanced, helpful offline AI assistant running locally on the user\'s hardware.',
      showThinking: _prefs?.getBool('showThinking') ?? true,
      showReasoning: _prefs?.getBool('showReasoning') ?? true,
    );
  }

  Future<void> updateTemperature(double val) async {
    state = state.copyWith(temperature: val);
    await _prefs?.setDouble('temperature', val);
  }

  Future<void> updateTopP(double val) async {
    state = state.copyWith(topP: val);
    await _prefs?.setDouble('topP', val);
  }

  Future<void> updateTopK(int val) async {
    state = state.copyWith(topK: val);
    await _prefs?.setInt('topK', val);
  }

  Future<void> updateMaxTokens(int val) async {
    state = state.copyWith(maxTokens: val);
    await _prefs?.setInt('maxTokens', val);
  }

  Future<void> updateSystemPrompt(String val) async {
    state = state.copyWith(systemPrompt: val);
    await _prefs?.setString('systemPrompt', val);
  }

  Future<void> updateShowThinking(bool val) async {
    state = state.copyWith(showThinking: val);
    await _prefs?.setBool('showThinking', val);
  }

  Future<void> updateShowReasoning(bool val) async {
    state = state.copyWith(showReasoning: val);
    await _prefs?.setBool('showReasoning', val);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
