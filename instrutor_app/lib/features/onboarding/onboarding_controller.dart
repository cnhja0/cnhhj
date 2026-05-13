import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enums.dart';
import '../../data/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/instructor_repository.dart';
import '../../data/repositories/repository_exception.dart';
import 'onboarding_draft.dart';

class OnboardingState {
  const OnboardingState({
    this.draft = const OnboardingDraft(),
    this.submitting = false,
    this.errorMessage,
  });

  final OnboardingDraft draft;
  final bool submitting;
  final String? errorMessage;

  OnboardingState copyWith({
    OnboardingDraft? draft,
    bool? submitting,
    String? errorMessage,
  }) {
    return OnboardingState(
      draft: draft ?? this.draft,
      submitting: submitting ?? this.submitting,
      errorMessage: errorMessage,
    );
  }
}

/// Mantém o rascunho do cadastro vivo enquanto o usuário navega entre os
/// passos. Só persiste no backend quando `submit()` é chamado no último passo.
class OnboardingController extends Notifier<OnboardingState> {
  static const int totalSteps = 7;

  @override
  OnboardingState build() => const OnboardingState();

  void updateDraft(OnboardingDraft Function(OnboardingDraft) update) {
    state = state.copyWith(draft: update(state.draft));
  }

  /// Submete o rascunho final criando/atualizando instructor + profile.
  /// Como estamos em MVP com aprovação automática, o profile já fica
  /// aprovado. As fotos seriam enviadas ao Storage real — no mock,
  /// salvamos só o caminho do arquivo como pseudo-URL.
  Future<bool> submit() async {
    state = state.copyWith(submitting: true);
    try {
      final AuthRepository auth = ref.read(authRepositoryProvider);
      final AuthSession? session = auth.currentSession;
      if (session == null) throw const UnauthenticatedException();

      final OnboardingDraft d = state.draft;
      final InstructorRepository repo = ref.read(instructorRepositoryProvider);

      await repo.updateProfile(
        session.userId,
        fullName: d.fullName,
        phone: d.phone,
        avatarUrl: d.profilePhoto?.path,
      );

      await repo.upsert(
        session.userId,
        InstructorUpdate(
          vehicleType: d.vehicleType,
          vehicleBrand: d.vehicleBrand,
          vehicleModel: d.vehicleModel,
          vehicleYear: d.vehicleYear,
          vehicleTransmission: d.vehicleTransmission,
          vehiclePlate: d.vehiclePlate,
          vehiclePhotoFrontUrl: d.vehiclePhotoFront?.path,
          vehiclePhotoBackUrl: d.vehiclePhotoBack?.path,
          cnhPhotoUrl: d.cnhPhoto?.path,
          detranCertificateUrl: d.detranCertificate?.path,
          categories: d.categories,
        ),
      );

      state = state.copyWith(submitting: false);
      return true;
    } on DataException catch (e) {
      state = state.copyWith(submitting: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        submitting: false,
        errorMessage: 'Não foi possível enviar o cadastro. Tente novamente.',
      );
      return false;
    }
  }

  /// Resetar o rascunho (útil ao sair sem concluir).
  void reset() => state = const OnboardingState();
}

final NotifierProvider<OnboardingController, OnboardingState>
    onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
