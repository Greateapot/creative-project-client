import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import 'widgets/pages/pages.dart';
import 'widgets/root.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => Root(
        state: state,
        shellContext: _shellNavigatorKey.currentContext,
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const ItemListPage(),
        ),
        GoRoute(
          path: '/list',
          name: 'list',
          builder: (context, state) => ItemListPage(
            ip: state.queryParameters['ip'],
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: '/server',
          name: 'server',
          builder: (context, state) => const ServerPage(),
        ),
      ],
    ),
  ],
);
