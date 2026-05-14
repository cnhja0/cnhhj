import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/sign_up_screen.dart';
import '../../features/chat/chat_list_screen.dart';
import '../../features/chat/chat_room_screen.dart';
import '../../features/home/home_shell.dart';
import '../../features/onboarding/analysis_screen.dart';
import '../../features/onboarding/finished_screen.dart';
import '../../features/onboarding/onboarding_flow_screen.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/reviews/reviews_screen.dart';
import 'app_routes.dart';

/// Cria uma `Page` com transição fade + slide-up suave.
///
/// Usado em todas as rotas para que nenhuma transição seja "corte seco".
/// Duração: 380ms entrando, 240ms saindo.
CustomTransitionPage<T> _fadeSlidePage<T>({
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      final Animation<double> curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Router principal do app, baseado em `go_router`. Todas as rotas usam
/// transição fade+slide via `_fadeSlidePage`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const SplashScreen(), state: state),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const LoginScreen(), state: state),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign-up',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const SignUpScreen(), state: state),
      ),
      GoRoute(
        path: '/onboarding/:step',
        name: 'onboarding-step',
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String stepStr = state.pathParameters['step'] ?? '1';
          final int step = int.tryParse(stepStr) ?? 1;
          return _fadeSlidePage(
            child: OnboardingFlowScreen(step: step),
            state: state,
          );
        },
      ),
      GoRoute(
        path: '/onboarding/analysis',
        name: 'onboarding-analysis',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const AnalysisScreen(), state: state),
      ),
      GoRoute(
        path: '/onboarding/finished',
        name: 'onboarding-finished',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const FinishedScreen(), state: state),
      ),
      // ─── Home (5 abas via IndexedStack: Home, Aula, Solicit., Agenda, Mais) ──
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const HomeShell(), state: state),
      ),
      GoRoute(
        path: AppRoutes.lesson,
        name: 'home-lesson',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(
              child: const HomeShell(initialTab: 1),
              state: state,
            ),
      ),
      GoRoute(
        path: AppRoutes.requests,
        name: 'home-requests',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(
              child: const HomeShell(initialTab: 2),
              state: state,
            ),
      ),
      GoRoute(
        path: AppRoutes.schedule,
        name: 'home-schedule',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(
              child: const HomeShell(initialTab: 3),
              state: state,
            ),
      ),
      GoRoute(
        path: AppRoutes.more,
        name: 'home-more',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(
              child: const HomeShell(initialTab: 4),
              state: state,
            ),
      ),
      // ─── Chat ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chat-list',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const ChatListScreen(), state: state),
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        name: 'chat-room',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(
              child: ChatRoomScreen(
                conversationId: state.pathParameters['conversationId']!,
              ),
              state: state,
            ),
      ),
      // ─── Reviews ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reviewsList,
        name: 'reviews',
        pageBuilder: (BuildContext context, GoRouterState state) =>
            _fadeSlidePage(child: const ReviewsScreen(), state: state),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Text('Rota não encontrada: ${state.uri}'),
      ),
    ),
  );
});
