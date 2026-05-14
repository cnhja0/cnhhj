import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';
import '../../models/profile.dart';
import '../auth_repository.dart';
import '../repository_exception.dart';
import '_seed.dart';

/// Implementação em memória do AuthRepository, com persistência da sessão
/// via `SharedPreferences` — assim o usuário não precisa logar de novo
/// depois de fechar e reabrir o app.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository();

  static const String _prefsUserId = 'auth.userId';
  static const String _prefsEmail = 'auth.email';

  AuthSession? _session;
  final StreamController<AuthSession?> _sessions =
      StreamController<AuthSession?>.broadcast();

  @override
  AuthSession? get currentSession => _session;

  @override
  Stream<AuthSession?> watchSession() => _sessions.stream;

  @override
  Future<void> restoreSession() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userId = prefs.getString(_prefsUserId);
      final String? email = prefs.getString(_prefsEmail);
      if (userId != null && email != null) {
        _session = AuthSession(userId: userId, email: email);
        _sessions.add(_session);
      }
    } catch (_) {
      // SharedPreferences indisponível — segue sem sessão restaurada.
    }
  }

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
    final AuthSession session =
        AuthSession(userId: cred.userId, email: email);
    return _emitAndPersist(session);
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    await _simulateNetwork();
    const String email = 'instrutor@cnhhj.com.br';
    final AuthSession session = AuthSession(
      userId: MockState.currentInstructorId,
      email: email,
    );
    return _emitAndPersist(session);
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

    final AuthSession session = AuthSession(userId: userId, email: email);
    return _emitAndPersist(session);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _simulateNetwork();
  }

  @override
  Future<void> signOut() async {
    await _simulateNetwork(short: true);
    _session = null;
    _sessions.add(null);
    await _persist();
  }

  // ─── helpers ──────────────────────────────────────────────────────
  Future<AuthSession> _emitAndPersist(AuthSession s) async {
    _session = s;
    _sessions.add(s);
    await _persist();
    return s;
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_session != null) {
        await prefs.setString(_prefsUserId, _session!.userId);
        await prefs.setString(_prefsEmail, _session!.email);
      } else {
        await prefs.remove(_prefsUserId);
        await prefs.remove(_prefsEmail);
      }
    } catch (_) {
      // Sem prefs, sessão fica só em memória nesta execução.
    }
  }

  Future<void> _simulateNetwork({bool short = false}) =>
      Future<void>.delayed(Duration(milliseconds: short ? 200 : 700));
}
