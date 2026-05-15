import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/conversation.dart';
import '../../data/models/message.dart';
import '../../data/providers.dart';
import '../../data/repositories/mock/_seed.dart';
import '../../shared/widgets/widgets.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;

    final AsyncValue<List<Conversation>> async =
        ref.watch(_conversationsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text('Conversas'),
      ),
      body: async.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.textPrimary),
        ),
        error: (Object err, _) => Center(child: Text('Erro: $err')),
        data: (List<Conversation> convs) {
          if (convs.isEmpty) {
            return const CnhhjEmptyState(
              icon: PhosphorIconsDuotone.chatCircleDots,
              message:
                  'Sem conversas ainda.\nQuando alunos te chamarem, elas aparecem aqui.',
            );
          }
          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext c, int i) {
              return _ConversationTile(conversation: convs[i])
                  .animate()
                  .fadeIn(delay: (i * 60).ms, duration: 300.ms)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOutCubic,
                  );
            },
          );
        },
      ),
    );
  }
}

final StreamProviderFamily<List<Conversation>, String> _conversationsProvider =
    StreamProvider.family<List<Conversation>, String>(
        (Ref ref, String userId) {
  return ref.watch(chatRepositoryProvider).watchConversations(userId);
});

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final String name =
        MockState.instance.profiles[conversation.studentId]?.fullName ?? 'Aluno';
    final List<Message> msgs =
        MockState.instance.messagesByConversation[conversation.id] ??
            const <Message>[];
    final Message? last = msgs.isEmpty ? null : msgs.last;
    final int unread = msgs
        .where((Message m) =>
            m.senderId != conversation.instructorId && m.readAt == null)
        .length;
    final DateFormat tf = DateFormat('HH:mm');

    return CnhhjCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/chats/${conversation.id}'),
      child: Row(
        children: <Widget>[
          Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              CnhhjAvatar(size: 52, fullName: name),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$unread',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (last != null)
                      Text(
                        tf.format(last.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: unread > 0
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontWeight: unread > 0
                              ? FontWeight.w800
                              : FontWeight.w500,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  last?.content ?? 'Toque para iniciar a conversa',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: unread > 0
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight:
                        unread > 0 ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            PhosphorIconsRegular.caretRight,
            size: 18,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
