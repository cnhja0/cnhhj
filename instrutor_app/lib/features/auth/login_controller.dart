import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';

class LoginState {
  const LoginState({
    this.loading = false,
    this.errorMessage,
  });

  final bool loading;
  final String? errorMessage;

  LoginState copyWith({bool? loading, String? errorMessage}) => LoginState(
        loading: loading ?? this.loading,
        errorMessage: errorMessage,
      );
}

class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const LoginState(loading: true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: email.trim(),
            password: password,
          );
      state = const LoginState();
      return true;
    } on DataException catch (e) {
      state = LoginState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const LoginState(
        errorMessage: 'Erro inesperado. Tente novamente.',
      );
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const LoginState(loading: true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const LoginState();
      return true;
    } on DataException catch (e) {
      state = LoginState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const LoginState(
        errorMessage: 'Não foi possível entrar com o Google.',
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith();
    }
  }
}

final NotifierProvider<LoginController, LoginState> loginControllerProvider =
    NotifierProvider<LoginController, LoginState>(LoginController.new);
