import '../models/enums.dart';
import '../models/profile.dart';

/// Sessão autenticada simplificada.
class AuthSession {
  const AuthSession({required this.userId, required this.email});

  final String userId;
  final String email;
}

/// Contrato de autenticação. Implementações: mock (em memória) e supabase.
abstract class AuthRepository {
  /// Sessão atual (null se não autenticado).
  AuthSession? get currentSession;

  /// Emite a sessão atual sempre que o estado muda (login, logout, refresh).
  Stream<AuthSession?> watchSession();

  /// Tenta restaurar uma sessão previamente persistida (após restart do app).
  ///
  /// - Mock: lê do SharedPreferences.
  /// - Supabase: o SDK do Supabase já restaura sessão automaticamente — a
  ///   implementação Supabase pode deixar isto como no-op.
  ///
  /// Deve ser chamado uma vez no início (Splash) antes de decidir a rota.
  Future<void> restoreSession();

  /// Carrega o profile do usuário atualmente logado.
  /// Lança `UnauthenticatedException` se não houver sessão.
  Future<Profile> currentProfile();

  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithGoogle();

  /// Cria conta nova; o profile é criado automaticamente via trigger no banco
  /// (no mock, é criado aqui mesmo).
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}
