import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Índice da aba ativa do HomeShell.
///
/// Centralizado em um StateProvider para que qualquer widget filho (ex:
/// cards do TabHome) consiga trocar de aba sem precisar de callbacks
/// passados pela hierarquia.
///
/// Ordem das abas:
///   0 = Home
///   1 = Aula
///   2 = Solicitações
///   3 = Agenda
///   4 = Mais
final StateProvider<int> tabIndexProvider = StateProvider<int>((Ref ref) => 0);
