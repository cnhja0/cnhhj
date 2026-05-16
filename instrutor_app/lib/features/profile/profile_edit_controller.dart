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

  /// Sentinel: distingue "não passou errorMessage" de "passou null".
  static const Object _kSentinel = Object();

  ProfileEditState copyWith({
    bool? saving,
    Object? errorMessage = _kSentinel,
  }) {
    return ProfileEditState(
      saving: saving ?? this.saving,
      errorMessage: identical(errorMessage, _kSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Controller para a tela de edição de perfil.
///
/// Salva profile (identidade pessoal) e instructor (bio + dados do veículo
/// visíveis para o aluno) em sequência. Invalida os providers correlatos
/// para que Home, Configurar Aula, Mais e a vitrine do aluno atualizem.
class ProfileEditController extends Notifier<ProfileEditState> {
  @override
  ProfileEditState build() => const ProfileEditState();

  Future<bool> save({
    required String userId,
    required String fullName,
    String? cpf,
    DateTime? birthDate,
    Gender? gender,
    String? phone,
    String? avatarUrl,
    String? bio,
    // Veículo — todos opcionais; só passa quando há mudança
    VehicleType? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    int? vehicleYear,
    Transmission? vehicleTransmission,
    String? vehiclePlate,
    String? vehiclePhotoFrontUrl,
    String? vehiclePhotoBackUrl,
    /// Quando o caller detecta que houve mudança real nos dados do veículo,
    /// passa `true` para o repo gravar `vehicleLastChangedAt = now` —
    /// trava o cooldown de 7 dias.
    bool vehicleChanged = false,
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

      // Junta bio + veículo num único upsert para minimizar round-trips.
      final bool hasInstructorPatch = bio != null ||
          vehicleType != null ||
          vehicleBrand != null ||
          vehicleModel != null ||
          vehicleYear != null ||
          vehicleTransmission != null ||
          vehiclePlate != null ||
          vehiclePhotoFrontUrl != null ||
          vehiclePhotoBackUrl != null;

      if (hasInstructorPatch) {
        await repo.upsert(
          userId,
          InstructorUpdate(
            bio: bio,
            vehicleType: vehicleType,
            vehicleBrand: vehicleBrand,
            vehicleModel: vehicleModel,
            vehicleYear: vehicleYear,
            vehicleTransmission: vehicleTransmission,
            vehiclePlate: vehiclePlate,
            vehiclePhotoFrontUrl: vehiclePhotoFrontUrl,
            vehiclePhotoBackUrl: vehiclePhotoBackUrl,
            vehicleLastChangedAt:
                vehicleChanged ? DateTime.now() : null,
          ),
        );
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
