import 'dart:async';

import '../../models/enums.dart';
import '../../models/profile.dart';
import '../auth_repository.dart';
import '../repository_exception.dart';
import '_seed.dart';

/// Implementação em memória do AuthRepository, usada quando `APP_MODE=mock`.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  AuthSession? _session;
  final StreamController<AuthSession?> _sessions =
      StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> watchSession() => _sessions.stream;

  @override
  Future<Profile> currentProfile() async {
    final AuthSession? s = _session;
    if (s == null) throw const UnauthenticatedException();
    final Profile? p = MockState.instance.profiles[s.userId];
    if (p == null) throw const UnauthenticatedException();
    return p;
  }

  @override
  Future<AuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _simulateNetwork();
    final ({String userId, String password})? cred =
        MockState.instance.emailToCredentials[email.toLowerCase()];
    if (cred == null || cred.password != password) {
      throw const InvalidCredentialsException();
    }
    return _emit(AuthSession(userId: cred.userId, email: email));
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    await _simulateNetwork();
    // Mock simples: loga sempre como o instrutor seed.
    final String email = 'instrutor@cnhhj.com.br';
    return _emit(AuthSession(
      userId: MockState.currentInstructorId,
      email: email,
    ));
  }

  @override
  Future<AuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    await _simulateNetwork();
    final String key = email.toLowerCase();
    if (MockState.instance.emailToCredentials.containsKey(key)) {
      throw const EmailAlreadyInUseException();
    }
    final String userId =
        'user-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    MockState.instance.emailToCredentials[key] =
        (userId: userId, password: password);

    final DateTime now = DateTime.now();
    MockState.instance.profiles[userId] = Profile(
      id: userId,
      role: role,
      fullName: fullName,
      approvalStatus: ApprovalStatus.approved, // auto-approve no MVP
      approvedAt: now,
      createdAt: now,
      updatedAt: now,
    );

    return _emit(AuthSession(userId: userId, email: email));
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _simulateNetwork();
    // No mock, apenas finge sucesso. Em produção dispara e-mail via Supabase.
  }

  @override
  Future<void> signOut() async {
    await _simulateNetwork(short: true);
    _session = null;
    _sessions.add(null);
  }

  // ─── helpers ──────────────────────────────────────────────────────
  AuthSession _emit(AuthSession s) {
    _session = s;
    _sessions.add(s);
    return s;
  }

  Future<void> _simulateNetwork({bool short = false}) => Future<void>.delayed(
        Duration(milliseconds: short ? 200 : 700),
      );
}
