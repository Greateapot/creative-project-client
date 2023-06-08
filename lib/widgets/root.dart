import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';
import 'package:api/models.dart' as models;

import 'winnavbar.dart';
import '../theme.dart';
import '../2i18nEx.dart';

class Root extends StatefulWidget {
  const Root({
    super.key,
    required this.child,
    required this.shellContext,
    required this.state,
  });

  final Widget child;
  final BuildContext? shellContext;
  final GoRouterState state;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  final API api = API();
  bool updating = false;

  late List<NavigationPaneItem> originalItems = [
    PaneItem(
      key: const Key('/'),
      icon: const Icon(FluentIcons.this_p_c),
      title: const Text(rootMenuHome),
      body: const SizedBox.shrink(),
      onTap: () {
        GoRouter router = GoRouter.of(context);
        if (router.location != '/') router.pushNamed('home');
      },
    ),
  ];
  late final List<NavigationPaneItem> footerItems = [
    PaneItemSeparator(),
    PaneItem(
      key: const Key('/server'),
      icon: const Icon(FluentIcons.server_processes),
      title: const Text(rootMenuServerSettings),
      body: const SizedBox.shrink(),
      onTap: () {
        GoRouter router = GoRouter.of(context);
        if (router.location != '/server') router.pushNamed('server');
      },
    ),
    PaneItem(
      key: const Key('/settings'),
      icon: const Icon(FluentIcons.settings),
      title: const Text(rootMenuSettings),
      body: const SizedBox.shrink(),
      onTap: () {
        GoRouter router = GoRouter.of(context);
        if (router.location != '/settings') router.pushNamed('settings');
      },
    ),
  ];

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouter.of(context).location;
    int indexOriginal = originalItems
        .where((element) => element.key != null)
        .toList()
        .indexWhere((element) => element.key == Key(location));

    if (indexOriginal == -1) {
      int indexFooter = footerItems
          .where((element) => element.key != null)
          .toList()
          .indexWhere((element) => element.key == Key(location));
      if (indexFooter == -1) {
        return 0;
      }
      return originalItems
              .where((element) => element.key != null)
              .toList()
              .length +
          indexFooter;
    } else {
      return indexOriginal;
    }
  }

  void getOnline() async {
    setState(() => updating = true);
    models.Online online;
    try {
      online = await api.online();
    } catch (_) {
      // TODO: check all exceptions
      online = const models.Online(online: []);
    }

    List<NavigationPaneItem> lOriginalItems = [
      PaneItem(
        key: const Key('/'),
        icon: const Icon(FluentIcons.this_p_c),
        title: const Text(rootMenuHome),
        body: const SizedBox.shrink(),
        onTap: () {
          GoRouter router = GoRouter.of(context);
          if (router.location != '/') router.pushNamed('home');
        },
      ),
    ];

    for (final String ip in online.online) {
      final String path = '/list?ip=$ip';
      lOriginalItems.add(
        PaneItem(
          key: Key(path),
          icon: const Icon(FluentIcons.pc1),
          title: Text(ip),
          body: const SizedBox.shrink(),
          onTap: () {
            GoRouter router = GoRouter.of(context);
            if (router.location != path) router.push(path);
          },
        ),
      );
    }
    originalItems = lOriginalItems;
    setState(() => updating = false);
  }

  @override
  void initState() {
    super.initState();
    getOnline();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Root Rebuild: ${originalItems.map((e) => e.key).join(', ')}");
    final appTheme = context.watch<AppTheme>();
    return NavigationView(
      key: GlobalKey(debugLabel: 'Navigation View Key'),
      appBar: const NavigationAppBar(
        automaticallyImplyLeading: false,
        title: DragToMoveArea(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              appTitle,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
        actions: WindowNavigationBar(),
      ),
      paneBodyBuilder: (item, child) {
        final name =
            item?.key is ValueKey ? (item!.key as ValueKey).value : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        selected: _calculateSelectedIndex(context),
        header: SizedBox(
          height: kOneLineTileHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(rootMenu),
                updating
                    ? const Padding(
                        padding: EdgeInsets.all(4),
                        child: SizedBox(
                          height: kOneLineTileHeight / 2,
                          width: kOneLineTileHeight / 2,
                          child: ProgressRing(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: getOnline,
                        icon: const Icon(FluentIcons.refresh),
                      ),
              ],
            ),
          ),
        ),
        displayMode: appTheme.displayMode,
        indicator: appTheme.indicator == NavigationIndicators.end
            ? const EndNavigationIndicator()
            : const StickyNavigationIndicator(),
        items: originalItems,
        footerItems: footerItems,
      ),
    );
  }
}
