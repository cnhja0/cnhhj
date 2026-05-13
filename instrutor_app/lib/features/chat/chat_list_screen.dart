import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
              icon: Icons.chat_bubble_outline,
              message: 'Sem conversas ainda.\nQuando alunos te chamarem, elas aparecem aqui.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: convs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext c, int i) =>
                _ConversationTile(conversation: convs[i]),
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
    final DateFormat tf = DateFormat('HH:mm');

    return CnhhjCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => context.push('/chats/${conversation.id}'),
      child: Row(
        children: <Widget>[
          CnhhjAvatar(size: 48, fullName: name),
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
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (last != null)
                      Text(
                        tf.format(last.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
                if (last != null)
                  Text(
                    last.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
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
