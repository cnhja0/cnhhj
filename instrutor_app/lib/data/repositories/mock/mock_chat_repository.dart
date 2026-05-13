import 'dart:async';

import '../../models/conversation.dart';
import '../../models/message.dart';
import '../chat_repository.dart';
import '_seed.dart';

class MockChatRepository implements ChatRepository {
  final StreamController<String> _conversationChanges =
      StreamController<String>.broadcast();
  final StreamController<String> _convListChanges =
      StreamController<String>.broadcast();

  @override
  Future<List<Conversation>> listConversations(String instructorId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _forInstructor(instructorId);
  }

  @override
  Stream<List<Conversation>> watchConversations(String instructorId) async* {
    yield _forInstructor(instructorId);
    await for (final _ in _convListChanges.stream) {
      yield _forInstructor(instructorId);
    }
  }

  @override
  Future<List<Message>> listMessages(String conversationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<Message>.unmodifiable(
      MockState.instance.messagesByConversation[conversationId] ??
          const <Message>[],
    );
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) async* {
    yield List<Message>.unmodifiable(
      MockState.instance.messagesByConversation[conversationId] ??
          const <Message>[],
    );
    await for (final String changed in _conversationChanges.stream) {
      if (changed == conversationId) {
        yield List<Message>.unmodifiable(
          MockState.instance.messagesByConversation[conversationId] ??
              const <Message>[],
        );
      }
    }
  }

  @override
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final Message msg = Message(
      id: 'msg-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}',
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      createdAt: DateTime.now(),
    );
    MockState.instance.messagesByConversation
        .putIfAbsent(conversationId, () => <Message>[])
        .add(msg);
    // Atualiza last_message_at na conversa
    final int idx = MockState.instance.conversations
        .indexWhere((Conversation c) => c.id == conversationId);
    if (idx != -1) {
      final Conversation old = MockState.instance.conversations[idx];
      MockState.instance.conversations[idx] = Conversation(
        id: old.id,
        instructorId: old.instructorId,
        studentId: old.studentId,
        lastMessageAt: msg.createdAt,
        createdAt: old.createdAt,
      );
    }
    _conversationChanges.add(conversationId);
    _convListChanges.add(conversationId);
    return msg;
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required String readerId,
  }) async {
    final List<Message>? msgs =
        MockState.instance.messagesByConversation[conversationId];
    if (msgs == null) return;
    final DateTime now = DateTime.now();
    for (int i = 0; i < msgs.length; i++) {
      if (msgs[i].senderId != readerId && msgs[i].readAt == null) {
        msgs[i] = msgs[i].copyWith(readAt: now);
      }
    }
    _conversationChanges.add(conversationId);
  }

  @override
  Future<void> blockOther({
    required String conversationId,
    required String blockerId,
    String? reason,
  }) async {
    // Mock: apenas marca em memória num set simples.
    // Não usado por outras telas no MVP além de visualmente confirmar.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  List<Conversation> _forInstructor(String id) {
    final List<Conversation> filtered = MockState.instance.conversations
        .where((Conversation c) => c.instructorId == id)
        .toList()
      ..sort((Conversation a, Conversation b) {
        final DateTime ta = a.lastMessageAt ?? a.createdAt;
        final DateTime tb = b.lastMessageAt ?? b.createdAt;
        return tb.compareTo(ta);
      });
    return filtered;
  }
}
