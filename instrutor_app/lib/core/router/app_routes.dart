/// Nomes e paths centralizados das rotas do app.
///
/// Usar sempre estes constantes em vez de strings literais para evitar
/// typos espalhados pelo código.
class AppRoutes {
  AppRoutes._();

  // ─── Onboarding ────────────────────────────────────────────────────
  static const String splash    = '/';
  static const String login     = '/login';
  static const String signUp    = '/sign-up';
  static const String onboarding = '/onboarding';
  static const String onboardingStep = '/onboarding/:step';
  static const String onboardingReview = '/onboarding/review';
  static const String onboardingFinished = '/onboarding/finished';

  // ─── Home (shell com bottom nav: Home · Aula · Solicitações · Agenda · Mais) ─
  static const String home          = '/home';
  static const String lesson        = '/home/aula';
  static const String requests      = '/home/solicitacoes';
  static const String schedule      = '/home/agenda';
  static const String more          = '/home/mais';
  // (rota financial removida — sem aba Financeiro no MVP)

  // ─── Detalhes ──────────────────────────────────────────────────────
  static const String chatList       = '/chats';
  static const String chatRoom       = '/chats/:conversationId';
  static const String reviewsList    = '/reviews';
  static const String profileEdit    = '/profile/edit';
  static const String notifications  = '/notifications';
  static const String guide          = '/guide';
  static const String support        = '/support';

  /// Perfil de um aluno (visto pelo instrutor). Aceita query param opcional
  /// `bookingId` — quando presente, mostra rodapé com Aceitar/Recusar.
  static const String studentProfile = '/students/:studentId';
}
