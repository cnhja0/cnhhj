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

/// Router principal do app, baseado em `go_router`.
final Provider<GoRouter> appRouterProvider = Provider<GoRouter>((Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        name: 'sign-up',
        builder: (BuildContext context, GoRouterState state) =>
            const SignUpScreen(),
      ),
      GoRoute(
        path: '/onboarding/:step',
        name: 'onboarding-step',
        builder: (BuildContext context, GoRouterState state) {
          final String stepStr = state.pathParameters['step'] ?? '1';
          final int step = int.tryParse(stepStr) ?? 1;
          return OnboardingFlowScreen(step: step);
        },
      ),
      GoRoute(
        path: '/onboarding/analysis',
        name: 'onboarding-analysis',
        builder: (BuildContext context, GoRouterState state) =>
            const AnalysisScreen(),
      ),
      GoRoute(
        path: '/onboarding/finished',
        name: 'onboarding-finished',
        builder: (BuildContext context, GoRouterState state) =>
            const FinishedScreen(),
      ),
      // ─── Home (5 abas via IndexedStack interno) ──────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.lesson,
        name: 'home-lesson',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(),
      ),
      GoRoute(
        path: AppRoutes.requests,
        name: 'home-requests',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(initialTab: 1),
      ),
      GoRoute(
        path: AppRoutes.schedule,
        name: 'home-schedule',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.financial,
        name: 'home-financial',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(initialTab: 3),
      ),
      GoRoute(
        path: AppRoutes.more,
        name: 'home-more',
        builder: (BuildContext context, GoRouterState state) =>
            const HomeShell(initialTab: 4),
      ),
      // ─── Chat ────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.chatList,
        name: 'chat-list',
        builder: (BuildContext context, GoRouterState state) =>
            const ChatListScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatRoom,
        name: 'chat-room',
        builder: (BuildContext context, GoRouterState state) =>
            ChatRoomScreen(
          conversationId: state.pathParameters['conversationId']!,
        ),
      ),
      // ─── Reviews ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.reviewsList,
        name: 'reviews',
        builder: (BuildContext context, GoRouterState state) =>
            const ReviewsScreen(),
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(
        child: Text('Rota não encontrada: ${state.uri}'),
      ),
    ),
  );
});
