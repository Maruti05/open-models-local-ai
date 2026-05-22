import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/chat_provider.dart';

class InputBar extends StatelessWidget {
  final ChatState chatState;
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onStop;
  final int activeFilesCount;
  final VoidCallback onRAGPressed;

  const InputBar({
    super.key,
    required this.chatState,
    required this.controller,
    required this.onSend,
    required this.onStop,
    required this.activeFilesCount,
    required this.onRAGPressed,
  });

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
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !chatState.isGenerating,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
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
            chatState.isGenerating
                ? _buildStopButton()
                : _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.vibrantIndigo, AppColors.neonCyan]),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
        onPressed: onSend,
      ),
    );
  }

  Widget _buildStopButton() {
    return GestureDetector(
      onTap: onStop,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 2),
        ),
        child: const Icon(Icons.stop_rounded, color: AppColors.error, size: 22),
      ),
    );
  }
}
