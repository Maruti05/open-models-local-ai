import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/file_context_service.dart';
import '../../../core/inference/hybrid_model_manager.dart';
import '../../settings/providers/settings_provider.dart';
import '../../model_manager/providers/model_provider.dart';

class ChatState {
  final List<Map<String, dynamic>> sessions;
  final String? activeSessionId;
  final List<Map<String, dynamic>> messages;
  final bool isGenerating;
  final String streamingMessage;
  final int offset;
  final bool hasReachedMax;
  final String? error;

  ChatState({
    this.sessions = const [],
    this.activeSessionId,
    this.messages = const [],
    this.isGenerating = false,
    this.streamingMessage = '',
    this.offset = 0,
    this.hasReachedMax = false,
    this.error,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? sessions,
    String? activeSessionId,
    List<Map<String, dynamic>>? messages,
    bool? isGenerating,
    String? streamingMessage,
    int? offset,
    bool? hasReachedMax,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      streamingMessage: streamingMessage ?? this.streamingMessage,
      offset: offset ?? this.offset,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  StreamSubscription<String>? _inferenceSubscription;

  ChatNotifier(this._ref) : super(ChatState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadSessions();
    if (state.sessions.isNotEmpty && state.activeSessionId == null) {
      final latest = state.sessions.first;
      await selectSession(latest['id'] as String);
    }
  }

  void _cancelInference() {
    _inferenceSubscription?.cancel();
    _inferenceSubscription = null;
  }

  Future<void> _loadSessions() async {
    final list = await DatabaseService.instance.getSessions();
    state = state.copyWith(sessions: list);
  }

  Future<void> selectSession(String sessionId) async {
    _cancelInference();
    state = state.copyWith(
      activeSessionId: sessionId,
      messages: [],
      offset: 0,
      hasReachedMax: false,
      streamingMessage: '',
      isGenerating: false,
    );
    await loadMoreMessages();
  }

  Future<void> loadMoreMessages() async {
    final sessionId = state.activeSessionId;
    if (sessionId == null || state.hasReachedMax) return;

    final list = await DatabaseService.instance.getMessagesPaginated(
      sessionId: sessionId,
      limit: 20,
      offset: state.offset,
    );

    state = state.copyWith(
      messages: [...state.messages, ...list],
      hasReachedMax: list.length < 20,
      offset: state.offset + list.length,
    );
  }

  Future<String> createNewSession(String modelName) async {
    _cancelInference();
    final settings = _ref.read(settingsProvider);
    final session = await DatabaseService.instance.createSession(
      modelName: modelName,
      systemPrompt: settings.systemPrompt,
    );

    await _loadSessions();
    state = state.copyWith(
      activeSessionId: session['id'] as String,
      messages: [],
      offset: 0,
      hasReachedMax: false,
      streamingMessage: '',
      isGenerating: false,
      error: null,
    );
    return session['id'] as String;
  }

  Future<void> deleteSession(String sessionId) async {
    await DatabaseService.instance.deleteSession(sessionId);
    await _loadSessions();

    if (state.activeSessionId == sessionId) {
      state = state.copyWith(
        activeSessionId: null,
        messages: [],
        offset: 0,
        hasReachedMax: false,
        streamingMessage: '',
        isGenerating: false,
      );
    }
  }

  Future<void> sendMessage(String text) async {
    String sessionId = state.activeSessionId ?? '';
    if (sessionId.isEmpty) {
      final modelState = _ref.read(modelProvider);
      final modelName = modelState.loadedModelId ?? 'unknown';
      sessionId = await createNewSession(modelName);
    }

    if (text.trim().isEmpty || state.isGenerating) return;

    final userMsg = await DatabaseService.instance.insertMessage(
      sessionId: sessionId,
      role: 'user',
      content: text.trim(),
    );

    state = state.copyWith(
      messages: [userMsg, ...state.messages],
      isGenerating: true,
      streamingMessage: '',
      error: null,
    );

    final settings = _ref.read(settingsProvider);
    final compiledSystemPrompt =
        await FileContextService.instance.buildSystemPromptWithContext(
            settings.systemPrompt);

    final chatMessages = <Map<String, String>>[
      {'role': 'system', 'content': compiledSystemPrompt},
    ];

    final chronologicalMessages = state.messages.reversed.toList();
    final recentMessages = chronologicalMessages.length > 30
        ? chronologicalMessages.sublist(chronologicalMessages.length - 30)
        : chronologicalMessages;

    for (final msg in recentMessages) {
      final role = msg['role'] as String;
      final content = msg['content'] as String;
      if (role == 'user' || role == 'assistant') {
        chatMessages.add({'role': role, 'content': content});
      }
    }

    final capturedSessionId = sessionId;

    _inferenceSubscription?.cancel();
    _inferenceSubscription = HybridModelManager.instance
        .generateChat(
          messages: chatMessages,
          template: HybridModelManager.instance.currentTemplate,
          maxTokens: settings.maxTokens,
          temperature: settings.temperature,
          topP: settings.topP,
          topK: settings.topK,
        )
        .listen(
          (token) {
            state = state.copyWith(
              streamingMessage: state.streamingMessage + token,
            );
          },
          onDone: () async {
            _inferenceSubscription = null;
            final responseContent = state.streamingMessage;

            if (capturedSessionId.isEmpty || responseContent.isEmpty) {
              state = state.copyWith(
                  isGenerating: false, streamingMessage: '');
              return;
            }

            if (state.activeSessionId != capturedSessionId) return;

            final msg = await DatabaseService.instance.insertMessage(
              sessionId: capturedSessionId,
              role: 'assistant',
              content: responseContent,
            );

            state = state.copyWith(
              isGenerating: false,
              streamingMessage: '',
              messages: [msg, ...state.messages],
            );
          },
          onError: (e) {
            _inferenceSubscription = null;
            state = state.copyWith(
              isGenerating: false,
              streamingMessage: '',
              error: 'Inference failed: ${e.toString()}',
            );
          },
        );
  }

  void stopGeneration() {
    _cancelInference();
    state = state.copyWith(
      isGenerating: false,
      streamingMessage: '',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  @override
  void dispose() {
    _cancelInference();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});
