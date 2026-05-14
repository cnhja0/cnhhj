import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/instructor_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../home/home_providers.dart';

class ProfileEditState {
  const ProfileEditState({
    this.saving = false,
    this.errorMessage,
  });

  final bool saving;
  final String? errorMessage;

  ProfileEditState copyWith({bool? saving, String? errorMessage}) {
    return ProfileEditState(
      saving: saving ?? this.saving,
      errorMessage: errorMessage,
    );
  }
}

/// Controller para a tela de edição de perfil.
///
/// O state guarda apenas flags transitórias (saving, erro). Os valores
/// dos campos vivem dentro do widget (TextEditingControllers) porque
/// pertencem ao form, não ao modelo persistente.
class ProfileEditController extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  /// Salva profile + bio (do instructor). Retorna true se salvou.
  Future<bool> save({
    required String userId,
    required String fullName,
    String? cpf,
    DateTime? birthDate,
    Gender? gender,
    String? phone,
    String? avatarUrl,
    String? bio,
  }) async {
    state = const ProfileEditState(saving: true);
    try {
      final InstructorRepository repo =
          ref.read(instructorRepositoryProvider);
      await repo.updateProfile(
        userId,
        fullName: fullName,
        cpf: cpf,
        birthDate: birthDate,
        gender: gender,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      if (bio != null) {
        await repo.upsert(userId, InstructorUpdate(bio: bio));
      }
      // Atualiza Home, TabMore, tela de Configurar Aula etc.
      ref.invalidate(currentProfileProvider);
      ref.invalidate(currentInstructorProvider);

      state = const ProfileEditState();
      return true;
    } on DataException catch (e) {
      state = ProfileEditState(errorMessage: e.message);
      return false;
    } catch (_) {
      state = const ProfileEditState(
        errorMessage: 'Não foi possível salvar. Tente novamente.',
      );
      return false;
    }
  }
}

final NotifierProvider<ProfileEditController, ProfileEditState>
    profileEditControllerProvider =
    NotifierProvider<ProfileEditController, ProfileEditState>(
  ProfileEditController.new,
);
