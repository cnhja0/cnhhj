import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/repository_exception.dart';

class SignUpState {
  const SignUpState({this.loading = false, this.errorMessage});

  final bool loading;
  final String? errorMessage;

  SignUpState copyWith({bool? loading, String? errorMessage}) => SignUpState(
        loading: loading ?? this.loading,
        errorMessage: errorMessage,
      );
}

class SignUpController extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  Future<bool> createInstructorAccount({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const SignUpState(loading: true);
    try {
      await ref.read(authRepositoryProvider).signUpWithEmail(
            email: email.trim(),
            password: password,
            fullName: fullName.trim(),
            role: UserRole.instrutor,
          );
      state = const SignUpState();
      return true;
    } on DataException catch (e) {
      state = SignUpState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const SignUpState(
        errorMessage: 'Não foi possível criar a conta. Tente novamente.',
      );
      return false;
    }
  }
}

final NotifierProvider<SignUpController, SignUpState> signUpControllerProvider =
    NotifierProvider<SignUpController, SignUpState>(SignUpController.new);
