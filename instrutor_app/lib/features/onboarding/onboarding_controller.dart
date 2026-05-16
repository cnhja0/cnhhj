import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  /// Sentinel: distingue "não passou errorMessage" de "passou null".
  /// Sem isso, `copyWith(submitting: false)` apagaria a mensagem de erro
  /// recém-setada por outra chamada.
  static const Object _kSentinel = Object();

  OnboardingState copyWith({
    OnboardingDraft? draft,
    bool? submitting,
    Object? errorMessage = _kSentinel,
  }) {
    return OnboardingState(
      draft: draft ?? this.draft,
      submitting: submitting ?? this.submitting,
      errorMessage: identical(errorMessage, _kSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

/// Mantém o rascunho do cadastro vivo enquanto o usuário navega entre os
/// passos. Só persiste no backend quando `submit()` é chamado no último passo.
///
/// A2: o draft textual é serializado em `SharedPreferences` a cada
/// `updateDraft` — assim o usuário não perde nome/CPF/veículo se fechar
/// o app no meio do onboarding. Fotos (File) NÃO persistem porque o cache
/// do SO pode ser limpo; quem voltar precisa re-tirar as fotos.
class OnboardingController extends Notifier<OnboardingState> {
  static const int totalSteps = 7;
  static const String _prefsDraft = 'onboarding.draft';

  @override
  OnboardingState build() {
    // Tenta restaurar em background sem bloquear a UI. O usuário pode
    // começar a digitar e o rehidrato sobrescreve se chegar a tempo —
    // edge case raro, aceitável.
    _restore();
    return const OnboardingState();
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_prefsDraft);
      final OnboardingDraft? loaded = OnboardingDraft.tryFromJsonString(raw);
      if (loaded != null) {
        state = state.copyWith(draft: loaded);
      }
    } catch (_) {
      // SharedPreferences indisponível — segue sem restaurar.
    }
  }

  Future<void> _persist(OnboardingDraft draft) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsDraft, draft.toJsonString());
    } catch (_) {
      // Sem prefs, fica só em memória nesta execução.
    }
  }

  Future<void> _clearPersisted() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsDraft);
    } catch (_) {}
  }

  void updateDraft(OnboardingDraft Function(OnboardingDraft) update) {
    final OnboardingDraft next = update(state.draft);
    state = state.copyWith(draft: next);
    _persist(next);
  }

  /// Submete o rascunho final criando/atualizando instructor + profile.
  /// Como estamos em MVP com aprovação automática, o profile já fica
  /// aprovado. As fotos seriam enviadas ao Storage real — no mock,
  /// salvamos só o caminho do arquivo como pseudo-URL.
  Future<bool> submit() async {
    state = state.copyWith(submitting: true, errorMessage: null);
    try {
      final AuthRepository auth = ref.read(authRepositoryProvider);
      final AuthSession? session = auth.currentSession;
      if (session == null) throw const UnauthenticatedException();

      final OnboardingDraft d = state.draft;
      final InstructorRepository repo = ref.read(instructorRepositoryProvider);

      await repo.updateProfile(
        session.userId,
        fullName: d.fullName,
        cpf: d.cpf,
        birthDate: d.birthDate,
        gender: d.gender,
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
          // I1: marca o relógio do cooldown já no cadastro. Assim, qualquer
          // ajuste pós-onboarding (ex: trocar foto do carro) cai sob o
          // mesmo regime de 7 dias — alinhando expectativa do usuário.
          vehicleLastChangedAt: DateTime.now(),
        ),
      );

      state = state.copyWith(submitting: false);
      // Cadastro persistido no backend — não precisamos mais do draft local.
      await _clearPersisted();
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

  /// Resetar o rascunho (útil ao sair sem concluir / logout / vazamento
  /// entre contas). Limpa também o storage persistido.
  void reset() {
    state = const OnboardingState();
    _clearPersisted();
  }
}

final NotifierProvider<OnboardingController, OnboardingState>
    onboardingControllerProvider =
    NotifierProvider<OnboardingController, OnboardingState>(
  OnboardingController.new,
);
