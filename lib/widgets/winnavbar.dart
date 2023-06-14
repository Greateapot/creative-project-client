import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

class WindowNavigationBar extends StatefulWidget {
  /// Кнопки свернуть, раскрыть, закрыть, но свои, чтоб красиво было.
  const WindowNavigationBar({super.key});

  @override
  State<WindowNavigationBar> createState() => _WindowNavigationBarState();
}

class _WindowNavigationBarState extends State<WindowNavigationBar>
    with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() {});
    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    setState(() {});
    super.onWindowUnmaximize();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // TODO: theme dark button
        IconButton(
          icon: const Icon(FluentIcons.chrome_minimize),
          onPressed: () => windowManager.minimize(),
        ),
        FutureBuilder(
          future: windowManager.isMaximized(),
          builder: (context, snapshot) {
            bool isMaximized = snapshot.hasData ? snapshot.data! : false;
            return IconButton(
              icon: isMaximized
                  ? const Icon(FluentIcons.chrome_restore)
                  : const Icon(FluentIcons.chrome_full_screen),
              onPressed: () => isMaximized
                  ? windowManager.unmaximize()
                  : windowManager.maximize(),
            );
          },
        ),
        IconButton(
          icon: const Icon(FluentIcons.chrome_close),
          onPressed: () => windowManager.close(),
        ),
      ],
    );
  }
}
