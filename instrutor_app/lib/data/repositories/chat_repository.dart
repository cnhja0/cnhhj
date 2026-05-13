import '../models/conversation.dart';
import '../models/message.dart';

abstract class ChatRepository {
  /// Conversas do instrutor, ordenadas por última mensagem.
  Future<List<Conversation>> listConversations(String instructorId);
  Stream<List<Conversation>> watchConversations(String instructorId);

  /// Mensagens de uma conversa específica.
  Future<List<Message>> listMessages(String conversationId);
  Stream<List<Message>> watchMessages(String conversationId);

  /// Envia uma mensagem em uma conversa existente.
  Future<Message> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
  });

  /// Marca todas as mensagens da conversa como lidas pelo usuário informado.
  Future<void> markAsRead({
    required String conversationId,
    required String readerId,
  });

  /// Bloqueia o outro participante. Quem é "o outro" é deduzido pela conversa.
  Future<void> blockOther({
    required String conversationId,
    required String blockerId,
    String? reason,
  });
}
