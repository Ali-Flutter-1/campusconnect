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
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';
import '../widgets/message_actions_sheet.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_details_sheet.dart';
import '../widgets/reply_quote.dart';

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
  final _focus = FocusNode();

  /// The message currently being edited, mirrored so the send button knows
  /// whether to submit an edit or a new message.
  String? _editingId;

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    final bloc = context.read<ChatBloc>();
    bloc.add(_editingId != null
        ? ChatEditSubmitted(text)
        : ChatSendRequested(text));
    _input.clear();
  }

  /// Mirrors the composer target into the text field: an edit prefills the text
  /// and focuses; leaving edit mode clears it. A reply only shows its banner.
  void _onComposerTargetChanged(ChatState state) {
    final editingId = state.editing?.id;
    if (editingId == _editingId) {
      if (state.replyingTo != null) _focus.requestFocus();
      return;
    }
    setState(() => _editingId = editingId);
    if (state.editing != null) {
      _input.text = state.editing!.content;
      _input.selection =
          TextSelection.collapsed(offset: _input.text.length);
      _focus.requestFocus();
    } else {
      _input.clear();
    }
  }

  Future<void> _openActions(ChatMessage message, ChatState state) async {
    final bloc = context.read<ChatBloc>();
    final isMine = state.isMine(message);
    final action = await showMessageActionsSheet(
      context,
      message: message,
      isMine: isMine,
      currentUserId: state.currentUserId,
    );
    if (action == null || !mounted) return;

    switch (action.kind) {
      case MessageActionKind.react:
        bloc.add(ChatReactionToggled(
          messageId: message.id,
          emoji: action.emoji!,
        ));
      case MessageActionKind.reply:
        bloc.add(ChatReplyStarted(message));
      case MessageActionKind.edit:
        bloc.add(ChatEditStarted(message));
      case MessageActionKind.copy:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Message copied')));
      case MessageActionKind.details:
        await showMessageDetailsSheet(
          context,
          message: message,
          isMine: isMine,
          currentUserId: state.currentUserId,
        );
      case MessageActionKind.delete:
        await _confirmDelete(message, bloc);
    }
  }

  Future<void> _confirmDelete(ChatMessage message, ChatBloc bloc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text(
          'It will be removed for everyone. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error.s400),
            ),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(ChatDeleteRequested(message.id));
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
                listenWhen: (p, c) =>
                    p.errorMessage != c.errorMessage ||
                    p.editing != c.editing ||
                    p.replyingTo != c.replyingTo,
                listener: (context, state) {
                  _onComposerTargetChanged(state);
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
                              currentUserId: state.currentUserId,
                              onRetry: () =>
                                  bloc.add(ChatRetryRequested(m.id)),
                              onTap: () => showMessageDetailsSheet(
                                context,
                                message: m,
                                isMine: state.isMine(m),
                                currentUserId: state.currentUserId,
                              ),
                              onLongPress: () => _openActions(m, state),
                              onToggleReaction: (emoji) => bloc.add(
                                ChatReactionToggled(
                                  messageId: m.id,
                                  emoji: emoji,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                  }
                },
              ),
            ),
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (p, c) =>
                  p.replyingTo != c.replyingTo || p.editing != c.editing,
              builder: (context, state) => _Composer(
                controller: _input,
                focusNode: _focus,
                replyingTo: state.replyingTo,
                editing: state.editing,
                onSend: _send,
                onCancelTarget: () =>
                    context.read<ChatBloc>().add(const ChatComposerCleared()),
              ),
            ),
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
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onCancelTarget,
    this.replyingTo,
    this.editing,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancelTarget;
  final ChatMessage? replyingTo;
  final ChatMessage? editing;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final target = editing ?? replyingTo;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (target != null) ...[
            ReplyQuote(
              senderName: editing != null
                  ? 'Editing your message'
                  : 'Replying to ${target.senderName}',
              content: target.content,
              deleted: target.isDeleted,
              onClose: onCancelTarget,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: AppTypography.inter(
                    size: AppTypography.base,
                    color: surfaces.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: editing != null
                        ? 'Edit your message…'
                        : 'Type a message…',
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      editing != null ? LucideIcons.check : LucideIcons.send,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
