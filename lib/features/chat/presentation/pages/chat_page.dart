import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_surfaces.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../injection.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_bubble.dart';

/// Global realtime chat. Anyone signed in can read and post; messages stream in
/// live via Supabase Realtime.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>(
      create: (_) => getIt<ChatBloc>()..add(const ChatStarted()),
      child: const _ChatView(),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    context.read<ChatBloc>().add(ChatSendRequested(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const _ChatHeader(),
            Expanded(
              child: BlocConsumer<ChatBloc, ChatState>(
                listenWhen: (p, c) => p.errorMessage != c.errorMessage,
                listener: (context, state) {
                  if (state.errorMessage != null) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                          SnackBar(content: Text(state.errorMessage!)));
                  }
                },
                builder: (context, state) {
                  switch (state.status) {
                    case ChatStatus.initial:
                    case ChatStatus.loading:
                      return const AppLoader();
                    case ChatStatus.failure when state.messages.isEmpty:
                      return ErrorView(
                        message: state.errorMessage ?? 'Could not load chat.',
                        onRetry: () =>
                            context.read<ChatBloc>().add(const ChatStarted()),
                      );
                    case ChatStatus.success:
                    case ChatStatus.failure:
                      if (state.messages.isEmpty) {
                        return const EmptyState(
                          icon: LucideIcons.messageSquare,
                          title: 'No messages yet',
                          subtitle: 'Say hello to the campus community!',
                        );
                      }
                      final bloc = context.read<ChatBloc>();
                      return NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          // Reversed list: the top (older history) is near the
                          // max scroll extent.
                          if (n.metrics.pixels >=
                              n.metrics.maxScrollExtent - 200) {
                            bloc.add(const ChatOlderRequested());
                          }
                          return false;
                        },
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          itemCount: state.messages.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= state.messages.length) {
                              return const Padding(
                                padding: EdgeInsets.all(AppSpacing.md),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            final m = state.messages[index];
                            return MessageBubble(
                              message: m,
                              isMine: state.isMine(m),
                            );
                          },
                        ),
                      );
                  }
                },
              ),
            ),
            _Composer(controller: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader();

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: surfaces.divider)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.s500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.circle,
                    size: 8, color: AppColors.success.s500),
                const SizedBox(width: 6),
                Text(
                  'Global Chat',
                  style: AppTypography.inter(
                    size: AppTypography.sm,
                    weight: AppTypography.semiBold,
                    color: AppColors.success.s400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: surfaces.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTypography.inter(
                size: AppTypography.base,
                color: surfaces.primaryText,
              ),
              decoration: InputDecoration(
                hintText: 'Type a message…',
                hintStyle: AppTypography.inter(
                  size: AppTypography.base,
                  color: surfaces.secondaryText,
                ),
                filled: true,
                fillColor: surfaces.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: surfaces.cardBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: surfaces.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide:
                      BorderSide(color: AppColors.primary.s500, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.primary.s500,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onSend,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(LucideIcons.send, size: 20, color: AppColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
