import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:api/api.dart';

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
  bool isUpdating = false;

  late final List<NavigationPaneItem> originalItems = [
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

  Future<void> _getOnline() async {
    if (isUpdating) return; // atomic-like
    setState(() => isUpdating = true);
    try {
      originalItems
        ..clear()
        ..addAll([
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
          for (final String ip in (await api.online()).online)
            PaneItem(
              key: Key('/list?ip=$ip'),
              icon: const Icon(FluentIcons.pc1),
              title: Text(ip),
              body: const SizedBox.shrink(),
              onTap: () {
                GoRouter router = GoRouter.of(context);
                if (router.location != '/list?ip=$ip') {
                  router.push('/list?ip=$ip');
                }
              },
            ),
        ]);
    } on NoConnectivityException {
      _showSnackbar("Err while getting online list: No internet connection.");
    } on FetchDataException catch (e) {
      _showSnackbar("Err while getting online list: ${e.message}.");
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Widget paneBodyBuilder(PaneItem? item, Widget? child) => FocusTraversalGroup(
        key: ValueKey('body${item?.key}'),
        child: widget.child,
      );

  void _showSnackbar(String data) {
    FluentThemeData theme = FluentTheme.of(context);
    showSnackbar(
      context,
      SnackbarTheme(
        data: SnackbarThemeData(
          padding: EdgeInsets.symmetric(
            vertical: 8.0 + theme.visualDensity.vertical,
            horizontal: 16.0 + theme.visualDensity.horizontal,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            color: theme.brightness == Brightness.light
                ? const Color(0xFFDEDEDE)
                : const Color(0xFF212121),
          ),
        ),
        child: Snackbar(
          content: Text(data),
          extended: true,
        ),
      ),
    );
  }

  @override
  void initState() {
    _getOnline();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // debugPrint("Root Rebuild: ${originalItems.map((e) => e.key).join(', ')}");
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
      paneBodyBuilder: paneBodyBuilder,
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
                const Spacer(),
                isUpdating
                    ? const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Center(
                          child: SizedBox.square(
                            dimension: kOneLineTileHeight / 2,
                            child: ProgressRing(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: _getOnline,
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
