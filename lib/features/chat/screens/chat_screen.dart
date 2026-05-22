import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/file_context_service.dart';
import '../../../core/widgets/info_guard.dart';
import '../../model_manager/providers/model_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/messages_list.dart';
import '../widgets/input_bar.dart';

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
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(chatProvider.notifier).loadMoreMessages();
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  Future<void> _loadActiveFiles() async {
    final files = await FileContextService.instance.getIngestedFiles();
    if (mounted) setState(() { _activeFiles = files; _activeFilesCount = files.length; });
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
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
              Text('Running: ${modelState.loadedModelId}', style: const TextStyle(fontSize: 11, color: AppColors.neonCyan))
            else
              const Text('Offline - No active weights', style: TextStyle(fontSize: 11, color: AppColors.error)),
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
                        child: Text('$_activeFilesCount', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
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
                    Expanded(child: Text(chatState.error!, style: const TextStyle(fontSize: 12, color: AppColors.error), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.close, color: AppColors.error, size: 14),
                  ],
                ),
              ),
            ),
          Expanded(
            child: !isModelLoaded
                ? const InfoGuard(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.error,
                    title: 'Inference Engine Cold',
                    subtitle: 'To start chatting entirely offline, you must load model weights into your device RAM memory first.',
                    footnote: 'Navigate to the Repository tab to download and load a model.',
                  )
                : chatState.activeSessionId == null
                    ? InfoGuard(
                        icon: Icons.forum_rounded,
                        iconColor: AppColors.neonCyan,
                        title: 'Create a Conversation',
                        subtitle: 'Your target model "${modelState.loadedModelId}" is loaded and primed. Tap below to spin up a thread-safe local chat session.',
                        buttonLabel: 'SPIN UP SESSION',
                        onButtonPressed: () => ref.read(chatProvider.notifier).createNewSession(modelState.loadedModelId!),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: MessagesList(
                              chatState: chatState,
                              scrollController: _scrollController,
                              onSend: _handleSend,
                              showThinking: ref.watch(settingsProvider).showThinking,
                              showReasoning: ref.watch(settingsProvider).showReasoning,
                            ),
                          ),
                          InputBar(
                            chatState: chatState,
                            controller: _messageController,
                            onSend: _handleSend,
                            onStop: () => ref.read(chatProvider.notifier).stopGeneration(),
                            activeFilesCount: _activeFilesCount,
                            onRAGPressed: () => _showRAGContextBottomSheet(context),
                          ),
                        ],
                      ),
          ),
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
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history_toggle_off_rounded, size: 36, color: AppColors.neonCyan),
                const SizedBox(height: 12),
                Text('Session History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                const SizedBox(height: 4),
                Text('${chatState.sessions.length} conversations', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Expanded(
            child: chatState.sessions.isEmpty
                ? Center(child: Text('No saved sessions.', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)))
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
                          final diff = DateTime.now().difference(dt);
                          timeDisplay = diff.inMinutes < 60 ? '${diff.inMinutes}m ago'
                              : diff.inHours < 24 ? '${diff.inHours}h ago'
                              : diff.inDays < 7 ? '${diff.inDays}d ago'
                              : '${dt.month}/${dt.day}/${dt.year}';
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isActive ? (isDark ? AppColors.darkCardBg : Colors.white) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? (isDark ? AppColors.darkBorder : AppColors.lightBorder) : Colors.transparent),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () { ref.read(chatProvider.notifier).selectSession(id); Navigator.pop(ctx); },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38, height: 38,
                                  decoration: BoxDecoration(color: AppColors.vibrantIndigo.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
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
                                            child: Text(modelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.w600, fontSize: 13,
                                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(timeDisplay, style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.message_outlined, size: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                          const SizedBox(width: 3),
                                          Text('$msgCount messages', style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                                        ],
                                      ),
                                      if (lastPreview != null && lastPreview.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(lastPreview, maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 11, color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.7))),
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

  void _showRAGContextBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkObsidian : AppColors.lightPorcelain,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)),
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
              Text('Files attached here will be compiled into system prompt directives and referenced locally by offline inference weights.',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, height: 1.4)),
              const SizedBox(height: 20),
              if (_activeFiles.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.snippet_folder_outlined,
                            color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.3), size: 40),
                        const SizedBox(height: 12),
                        Text('No context files active',
                            style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
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
                          label: const Text('LOAD CORE SPEC PRESETS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _activeFiles.length,
                    separatorBuilder: (_, _) => Divider(height: 16, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                                      Text(file.filename, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text('${file.content.length} characters loaded',
                                          style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
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
            child: Text('CANCEL', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
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
}
