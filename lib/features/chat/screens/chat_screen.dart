import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/file_context_service.dart';
import '../../model_manager/providers/model_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/ai_message_widget.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  int _activeFilesCount = 0;
  List<LocalFileContext> _activeFiles = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadActiveFiles();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  Future<void> _loadActiveFiles() async {
    final files = await FileContextService.instance.getIngestedFiles();
    if (mounted) {
      setState(() {
        _activeFiles = files;
        _activeFilesCount = files.length;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _messageController.clear();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _showRAGContextBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkObsidian : AppColors.lightPorcelain,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LOCAL RAG CONTEXT',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              letterSpacing: 1.5)),
                      const SizedBox(height: 4),
                      Text('Injected Files (${_activeFiles.length})',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.neonCyan),
                    onPressed: () => _showAddContextFileDialog(context, () {
                      _loadActiveFiles().then((_) => setModalState(() {}));
                    }),
                    tooltip: 'Add Custom Context Document',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Files attached here will be compiled into system prompt directives and referenced locally by offline inference weights.',
                style: TextStyle(fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4)),
              const SizedBox(height: 20),
              if (_activeFiles.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.snippet_folder_outlined,
                            color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3),
                            size: 40),
                        const SizedBox(height: 12),
                        Text('No context files active',
                            style: TextStyle(fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                fontSize: 13)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            foregroundColor: isDark ? Colors.white : AppColors.lightTextPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _loadPresetContextFiles(() {
                            _loadActiveFiles().then((_) => setModalState(() {}));
                          }),
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text('LOAD CORE SPEC PRESETS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _activeFiles.length,
                    separatorBuilder: (_, _) => Divider(height: 16,
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    itemBuilder: (ctx, index) {
                      final file = _activeFiles[index];
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.description_rounded, color: AppColors.vibrantIndigo, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(file.filename,
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('${file.content.length} characters loaded',
                                          style: TextStyle(fontSize: 10,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 18),
                            onPressed: () async {
                              await FileContextService.instance.deleteFile(file.id);
                              await _loadActiveFiles();
                              setModalState(() {});
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddContextFileDialog(BuildContext context, VoidCallback onCompleted) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        title: Text('Ingest Context Document',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Document Name (e.g. guide.txt)',
                hintText: 'specifications.md',
                labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
              ),
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Document Content',
                hintText: 'Paste target instructions here...',
                labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5)),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
              ),
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL',
                style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = titleController.text.trim();
              final body = bodyController.text.trim();
              if (name.isNotEmpty && body.isNotEmpty) {
                await FileContextService.instance.ingestFile(name, body);
                onCompleted();
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('INGEST'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPresetContextFiles(VoidCallback onCompleted) async {
    await FileContextService.instance.ingestFile(
      'flutter_bridge_api.md',
      '# Method and Event Channels\n\n'
      '- Diagnostics Channel: `com.vedica.labs/diagnostics` maps physical RAM metrics.\n'
      '- Download Stream: `com.vedica.labs/download_stream` chunked downloader coroutine telemetry.\n'
      '- Inference Stream: `com.vedica.labs/inference_stream` GGUF local model streaming tokens token-by-token.',
    );
    await FileContextService.instance.ingestFile(
      'hyperparameter_guide.txt',
      'TEMPERATURE TUNING MATRIX:\n'
      '- Temp 0.1 to 0.4: Optimal for code syntax, logical parameters, and factual documentation.\n'
      '- Temp 0.7 to 1.0: Optimal for dialogue flows, creative essays, copy edits, and writing prompts.',
    );
    onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final modelState = ref.watch(modelProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isModelLoaded = modelState.loadedModelId != null;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Local Inference',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            if (isModelLoaded)
              Text('Running: ${modelState.loadedModelId}',
                  style: const TextStyle(fontSize: 11, color: AppColors.neonCyan))
            else
              const Text('Offline - No active weights',
                  style: TextStyle(fontSize: 11, color: AppColors.error)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isModelLoaded) ...[
            IconButton(
              icon: Stack(
                alignment: Alignment.topRight,
                children: [
                  const Icon(Icons.snippet_folder_rounded, color: AppColors.neonCyan),
                  if (_activeFilesCount > 0)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.vibrantIndigo, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                        child: Text('$_activeFilesCount',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              onPressed: () => _showRAGContextBottomSheet(context),
              tooltip: 'Attach Custom RAG Context',
            ),
            IconButton(
              icon: const Icon(Icons.add_comment_rounded, color: AppColors.neonCyan),
              onPressed: () => ref.read(chatProvider.notifier).createNewSession(modelState.loadedModelId!),
              tooltip: 'New Conversation',
            ),
          ]
        ],
      ),
      drawer: _buildSessionsDrawer(chatState, isDark),
      body: Column(
        children: [
          if (chatState.error != null)
            GestureDetector(
              onTap: () => ref.read(chatProvider.notifier).clearError(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.error.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        chatState.error!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.close, color: AppColors.error, size: 14),
                  ],
                ),
              ),
            ),
          if (!isModelLoaded)
            const Expanded(child: _UnloadedModelGuard())
          else if (chatState.activeSessionId == null)
            Expanded(child: _NoSessionGuard(
              modelId: modelState.loadedModelId!,
              onCreateSession: () => ref.read(chatProvider.notifier).createNewSession(modelState.loadedModelId!),
            ))
          else ...[
            Expanded(child: _MessagesList(
              chatState: chatState,
              scrollController: _scrollController,
              onSend: _handleSend,
              showThinking: ref.watch(settingsProvider).showThinking,
              showReasoning: ref.watch(settingsProvider).showReasoning,
            )),
            _InputBar(
              chatState: chatState,
              controller: _messageController,
              onSend: _handleSend,
              activeFilesCount: _activeFilesCount,
              onRAGPressed: () => _showRAGContextBottomSheet(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionsDrawer(ChatState chatState, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkObsidian : AppColors.lightPorcelain,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.neonCyan),
                const SizedBox(height: 12),
                Text('Session History',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const SizedBox(height: 4),
                Text('${chatState.sessions.length} conversations',
                    style: TextStyle(fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Expanded(
            child: chatState.sessions.isEmpty
                ? Center(
                    child: Text('No saved sessions.',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: chatState.sessions.length,
                    itemBuilder: (ctx, index) {
                      final session = chatState.sessions[index];
                      final id = session['id'] as String;
                      final modelName = session['model_name'] as String? ?? 'Unknown';
                      final isActive = chatState.activeSessionId == id;
                      final createdAt = session['created_at'] as String? ?? '';
                      final msgCount = session['message_count'] as int? ?? 0;
                      final lastPreview = session['last_message_preview'] as String?;

                      String timeDisplay = '';
                      if (createdAt.isNotEmpty) {
                        final dt = DateTime.tryParse(createdAt);
                        if (dt != null) {
                          final now = DateTime.now();
                          final diff = now.difference(dt);
                          if (diff.inMinutes < 60) {
                            timeDisplay = '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            timeDisplay = '${diff.inHours}h ago';
                          } else if (diff.inDays < 7) {
                            timeDisplay = '${diff.inDays}d ago';
                          } else {
                            timeDisplay = '${dt.month}/${dt.day}/${dt.year}';
                          }
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isActive ? (isDark ? AppColors.darkCardBg : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isActive ? (isDark ? AppColors.darkBorder : AppColors.lightBorder) : Colors.transparent,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            ref.read(chatProvider.notifier).selectSession(id);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.vibrantIndigo.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.chat_rounded, size: 18, color: AppColors.vibrantIndigo),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              modelName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                                fontSize: 13,
                                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            timeDisplay,
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.message_outlined, size: 10,
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          const SizedBox(width: 3),
                                          Text('$msgCount messages',
                                              style: TextStyle(fontSize: 10,
                                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                        ],
                                      ),
                                      if (lastPreview != null && lastPreview.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          lastPreview,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark ? AppColors.darkTextSecondary.withValues(alpha: 0.7) : AppColors.lightTextSecondary.withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 16),
                                  onPressed: () => ref.read(chatProvider.notifier).deleteSession(id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Unloaded Model Guard ────────────────────────────────────────

class _UnloadedModelGuard extends StatelessWidget {
  const _UnloadedModelGuard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.bolt_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            Text('Inference Engine Cold',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 12),
            Text('To start chatting entirely offline, you must load model weights into your device RAM memory first.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 24),
            Text('Navigate to the Repository tab to download and load a model.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── No Session Guard ────────────────────────────────────────────

class _NoSessionGuard extends StatelessWidget {
  const _NoSessionGuard({required this.modelId, required this.onCreateSession});
  final String modelId;
  final VoidCallback onCreateSession;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.08), shape: BoxShape.circle),
              child: const Icon(Icons.forum_rounded, size: 48, color: AppColors.neonCyan),
            ),
            const SizedBox(height: 24),
            Text('Create a Conversation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            const SizedBox(height: 12),
            Text('Your target model "$modelId" is loaded and primed. Tap below to spin up a thread-safe local chat session.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onCreateSession,
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              label: const Text('SPIN UP SESSION'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Messages List ───────────────────────────────────────────────

class _MessagesList extends StatelessWidget {
  const _MessagesList({
    required this.chatState,
    required this.scrollController,
    required this.onSend,
    required this.showThinking,
    required this.showReasoning,
  });

  final ChatState chatState;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final bool showThinking;
  final bool showReasoning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final messages = chatState.messages;
    final totalCount = messages.length + (chatState.isGenerating ? 1 : 0);

    if (messages.isEmpty && !chatState.isGenerating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.textsms_outlined,
                color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3),
                size: 36),
            const SizedBox(height: 16),
            Text('Empty Thread',
                style: TextStyle(fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
            const SizedBox(height: 4),
            Text('Ask a prompt to begin native GGUF execution.',
                style: TextStyle(fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (chatState.isGenerating && index == 0) {
          return _MessageBubble(
            role: 'assistant',
            content: chatState.streamingMessage,
            isStreaming: true,
            isFirstInGroup: true,
            isLastInGroup: index == totalCount - 1,
            showThinking: showThinking,
            showReasoning: showReasoning,
          );
        }

        final msgIndex = index - (chatState.isGenerating ? 1 : 0);
        final message = messages[msgIndex];
        final role = message['role'] as String;
        final content = message['content'] as String;
        final tps = message['tokens_per_second'] as double?;
        final prevRole = msgIndex < messages.length - 1 ? messages[msgIndex + 1]['role'] as String : null;
        final nextRole = msgIndex > 0 ? messages[msgIndex - 1]['role'] as String : null;

        return _MessageBubble(
          role: role,
          content: content,
          tokensPerSec: tps,
          isFirstInGroup: prevRole != role,
          isLastInGroup: nextRole != role,
          showThinking: showThinking,
          showReasoning: showReasoning,
        );
      },
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.role,
    required this.content,
    this.tokensPerSec,
    this.isStreaming = false,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.showThinking = true,
    this.showReasoning = true,
  });

  final String role;
  final String content;
  final double? tokensPerSec;
  final bool isStreaming;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showThinking;
  final bool showReasoning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUser = role == 'user';
    final tps = tokensPerSec;

    Color bgColor;
    Color borderColor;
    if (isUser) {
      bgColor = isDark
          ? AppColors.vibrantIndigo.withValues(alpha: 0.2)
          : AppColors.vibrantIndigo.withValues(alpha: 0.1);
      borderColor = AppColors.vibrantIndigo.withValues(alpha: 0.25);
    } else {
      bgColor = isDark ? AppColors.darkCardBg : Colors.white;
      borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    }

    final verticalMargin = isFirstInGroup && isLastInGroup
        ? 6.0
        : isFirstInGroup || isLastInGroup
            ? 4.0
            : 0.5;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: verticalMargin),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(
                  isUser ? 18 : (isLastInGroup ? 18 : 4)),
              bottomRight: Radius.circular(
                  isUser ? (isLastInGroup ? 4 : 18) : 18),
            ),
            border: Border.all(color: borderColor, width: 0.8),
            boxShadow: isFirstInGroup
                ? [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isFirstInGroup)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    isUser ? 'You' : 'Agent',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isUser
                          ? AppColors.vibrantIndigo.withValues(alpha: 0.8)
                          : AppColors.neonCyan.withValues(alpha: 0.8),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              if (isUser)
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                )
              else
                AiMessageWidget(
                  content: content,
                  isStreaming: isStreaming,
                  showThinking: showThinking,
                  showReasoning: showReasoning,
                ),
              if (!isUser && tps != null && !isStreaming) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 10,
                        color: AppColors.neonCyan.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text('${tps.toStringAsFixed(1)} tok/s',
                        style: TextStyle(fontSize: 9,
                            color: AppColors.neonCyan.withValues(alpha: 0.7))),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stream Pulse Animation ──────────────────────────────────────

class _StreamPulse extends StatefulWidget {
  const _StreamPulse();

  @override
  State<_StreamPulse> createState() => _StreamPulseState();
}

class _StreamPulseState extends State<_StreamPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = i * 0.15;
              final t = (_controller.value - delay).clamp(0.0, 1.0);
              final opacity = (t < 0.5) ? 0.3 + 0.7 * (t / 0.5) : 1.0 - 0.7 * ((t - 0.5) / 0.5);
              return Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: AppColors.neonCyan.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

// ─── Input Bar ───────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.chatState,
    required this.controller,
    required this.onSend,
    required this.activeFilesCount,
    required this.onRAGPressed,
  });

  final ChatState chatState;
  final TextEditingController controller;
  final VoidCallback onSend;
  final int activeFilesCount;
  final VoidCallback onRAGPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.only(
        left: 8, right: 8, bottom: MediaQuery.of(context).padding.bottom + 8, top: 8,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkObsidian : AppColors.lightPorcelain,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black12).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              padding: const EdgeInsets.all(8),
              icon: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  Icon(Icons.snippet_folder_rounded, color: AppColors.neonCyan, size: 24),
                  if (activeFilesCount > 0)
                    Positioned(
                      right: -4, top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: AppColors.vibrantIndigo, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text('$activeFilesCount',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                            textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
              onPressed: onRAGPressed,
              tooltip: 'Attach Custom RAG Context',
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardBg : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !chatState.isGenerating,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.vibrantIndigo, AppColors.neonCyan],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                onPressed: chatState.isGenerating ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
