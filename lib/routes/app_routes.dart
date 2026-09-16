import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/calendar_screen/calendar_screen.dart';
import '../presentation/history_screen/history_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../widgets/app_scaffold.dart';

class AppRoutes {
  static const String initial = '/home-screen';
  static const String homeScreen = '/home-screen';
  static const String calendarScreen = '/calendar-screen';
  static const String historyScreen = '/history-screen';
  static const String settingsScreen = '/settings-screen';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.homeScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HomeScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.calendarScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const CalendarScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.historyScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const HistoryScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settingsScreen,
              pageBuilder: (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 280),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
