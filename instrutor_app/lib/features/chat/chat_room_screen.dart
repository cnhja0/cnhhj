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

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({super.key, required this.conversationId});
  final String conversationId;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    await ref.read(chatRepositoryProvider).sendMessage(
          conversationId: widget.conversationId,
          senderId: userId,
          content: text,
        );
  }

  Future<void> _blockOther() async {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final bool? confirmed = await showCnhhjModal<bool>(
      context: context,
      icon: PhosphorIconsRegular.prohibit,
      title: 'Bloquear este aluno?',
      message:
          'O aluno não conseguirá mais enviar mensagens nem agendar aulas com você.',
      primaryLabel: 'Bloquear',
      onPrimary: () => Navigator.of(context).pop(true),
      secondaryLabel: 'Cancelar',
      onSecondary: () => Navigator.of(context).pop(false),
    );
    if (confirmed != true) return;
    await ref.read(chatRepositoryProvider).blockOther(
          conversationId: widget.conversationId,
          blockerId: userId,
        );
    if (!mounted) return;
    CnhhjSnack.info(context, 'Aluno bloqueado.');
  }

  @override
  Widget build(BuildContext context) {
    final String userId =
        ref.read(authRepositoryProvider).currentSession?.userId ??
            MockState.currentInstructorId;
    final Conversation? conv = MockState.instance.conversations
        .where((Conversation c) => c.id == widget.conversationId)
        .firstOrNull;
    final String otherName = conv == null
        ? 'Conversa'
        : (MockState.instance.profiles[conv.studentId]?.fullName ?? 'Aluno');
    final AsyncValue<List<Message>> async =
        ref.watch(_messagesProvider(widget.conversationId));

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: <Widget>[
            CnhhjAvatar(size: 36, fullName: otherName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    otherName,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Aluno',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(PhosphorIconsRegular.prohibit),
            tooltip: 'Bloquear',
            onPressed: _blockOther,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.textPrimary),
              ),
              error: (Object err, _) => Center(child: Text('Erro: $err')),
              data: (List<Message> msgs) {
                if (msgs.isEmpty) {
                  return const CnhhjEmptyState(
                    icon: PhosphorIconsDuotone.chatCircleDots,
                    message: 'Nenhuma mensagem ainda.\nMande um oi!',
                  );
                }
                return ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: msgs.length,
                  itemBuilder: (BuildContext c, int i) {
                    final Message m = msgs[i];
                    final bool mine = m.senderId == userId;
                    return _Bubble(message: m, mine: mine)
                        .animate()
                        .fadeIn(duration: 250.ms)
                        .slideX(
                          begin: mine ? 0.1 : -0.1,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        );
                  },
                );
              },
            ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

final StreamProviderFamily<List<Message>, String> _messagesProvider =
    StreamProvider.family<List<Message>, String>((Ref ref, String convId) {
  return ref.watch(chatRepositoryProvider).watchMessages(convId);
});

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final Message message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final DateFormat tf = DateFormat('HH:mm');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: mine ? AppColors.textPrimary : AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(mine ? 16 : 4),
                bottomRight: Radius.circular(mine ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.content,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: mine ? AppColors.surface : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tf.format(message.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: mine
                        ? AppColors.surface.withOpacity(0.7)
                        : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatefulWidget {
  const _Composer({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    final bool has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 10,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: widget.controller,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Mensagem',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                filled: true,
                fillColor: AppColors.primaryLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => widget.onSend(),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedScale(
            scale: _hasText ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            child: Material(
              color: _hasText ? AppColors.textPrimary : AppColors.disabled,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _hasText ? widget.onSend : null,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    PhosphorIconsFill.paperPlaneTilt,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
