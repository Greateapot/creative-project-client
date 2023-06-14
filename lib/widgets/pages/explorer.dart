import 'package:creative_project_client/2i18nEx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:fluent_ui/fluent_ui.dart';
import 'package:creative_project_client/widgets/dialogs/add.dart';
import 'package:api/api.dart';
import 'package:api/models.dart' as models;
import 'package:url_launcher/url_launcher.dart';

enum SortType {
  az("A-Z"), // by title
  za("Z-A"); // by title + reverse
  // dt, // by date
  // td, // by date + reverse

  const SortType(this.title);

  final String title;
}

class Explorer extends StatefulWidget {
  final String? ip;

  const Explorer({super.key, this.ip});

  @override
  State<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends State<Explorer> {
  final controller = FlyoutController();
  final double width = 150; // cfg load; mv to ctrl
  final API api = API(); // singleton-service

  final List<models.Item> selected = [];
  final List<models.Item> downloading = [];

  SortType sortType = SortType.az;

  late Future<models.Items> _future;

  Future<models.Items> _getItems([models.Items? items]) async {
    items ??= await api.list(widget.ip);

    final List<models.Item> files = items.items
        .where((element) => element.type == models.ItemType.file)
        .toList(growable: false);
    final List<models.Item> folders = items.items
        .where((element) => element.type == models.ItemType.folder)
        .toList(growable: false);
    final List<models.Item> links = items.items
        .where((element) => element.type == models.ItemType.link)
        .toList(growable: false);

    switch (sortType) {
      case SortType.az:
        files.sort((a, b) => a.title.compareTo(b.title));
        folders.sort((a, b) => a.title.compareTo(b.title));
        links.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortType.za:
        files.sort((a, b) => b.title.compareTo(a.title));
        folders.sort((a, b) => b.title.compareTo(a.title));
        links.sort((a, b) => b.title.compareTo(a.title));
        break;
    }

    return models.Items(items: [...folders, ...files, ...links]);
  }

  void addNewItem() async {
    models.Item? item = await showDialog(
      context: context,
      builder: (_) => const AddItemDialog(),
      barrierDismissible: true,
    );

    if (item != null) {
      try {
        await api.add(item);
        setState(() {
          _future = _getItems();
        });
      } on models.Error catch (e) {
        _showSnackbar("Err while deleting item: ${e.message}.");
      }
    }
  }

  void deleteSelectedItems() async {
    final List<models.Item> err = [];
    for (final models.Item item in selected.toList(/* create copy */)) {
      selected.remove(item);
      try {
        await api.del(item.title);
      } on models.Error {
        err.add(item);
      }
    }
    if (err.isNotEmpty) {
      _showSnackbar("Err while deleting items: ${err.join(', ')}.");
    }
    setState(() {
      _future = _getItems();
    });
  }

  void downloadSelectedItems() async {
    final List<models.Item> err = [];
    setState(() {
      downloading.addAll(selected);
      selected.clear();
    });
    for (final models.Item item in downloading.toList(/* create copy */)) {
      try {
        await api.downloadFile(
          item.title,
          path.join((await getDownloadsDirectory())!.path, item.title),
          widget.ip,
        );
      } on models.Error {
        err.add(item);
      } finally {
        setState(() {
          downloading.remove(item);
        });
      }
    }
    if (err.isNotEmpty) {
      _showSnackbar("Err while downloading items: ${err.join(', ')}.");
    }
    setState(() {
      _future = _getItems();
    });
  }

  void openLink(models.Item item) async {
    try {
      models.Link link = await api.getLink(item.title, widget.ip);
      if (!await launchUrl(Uri.parse(link.link))) {
        _showSnackbar("Something went wrong while open link");
      }
    } on models.Error catch (e) {
      _showSnackbar(e.message);
    }
  }

  void _showFlyout(models.Item item) async {
    controller.showFlyout(
      autoModeConfiguration: FlyoutAutoConfiguration(
        preferredMode: FlyoutPlacementMode.topCenter,
      ),
      barrierDismissible: true,
      dismissOnPointerMoveAway: false,
      dismissWithEsc: true,
      builder: (context) {
        return MenuFlyout(
          items: [
            MenuFlyoutItem(
              leading: item.type == models.ItemType.file
                  ? const Icon(FluentIcons.download)
                  : item.type == models.ItemType.link
                      ? const Icon(FluentIcons.open_in_new_window)
                      : const Icon(FluentIcons.folder_open),
              text: item.type == models.ItemType.file
                  ? const Text('download')
                  : item.type == models.ItemType.link
                      ? const Text("open in browser")
                      : const Text("open"),
              onPressed: () {
                if (item.type == models.ItemType.file) {
                  selected.add(item);
                  downloadSelectedItems();
                } else if (item.type == models.ItemType.link) {
                  openLink(item);
                } else {
                  _showSnackbar(later);
                }
                Flyout.of(context).close;
              },
            ),
            MenuFlyoutItem(
              leading: const Icon(FluentIcons.delete),
              text: const Text('Delete'),
              onPressed: () {
                selected.add(item);
                deleteSelectedItems();
                Flyout.of(context).close;
              },
            ),
          ],
        );
      },
    );
  }

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

  Widget buildHeader(BuildContext context) {
    return FutureBuilder<models.Items>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        models.Items items = snapshot.data!;
        return Row(
          children: [
            const Spacer(),
            if (selected.isEmpty)
              ComboBox<SortType>(
                items: [
                  for (SortType value in SortType.values)
                    ComboBoxItem(value: value, child: Text(value.title)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _future = _getItems(items);
                    });
                  }
                },
                value: sortType,
              ),
            IconButton(
              icon: const Icon(FluentIcons.refresh),
              onPressed: () => setState(() {
                _future = _getItems();
              }),
            ),
            if (selected.isEmpty)
              IconButton(
                icon: const Icon(FluentIcons.add),
                onPressed: addNewItem,
              ),
            if (selected.isNotEmpty)
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: deleteSelectedItems,
              ),
            if (selected.isNotEmpty &&
                selected.every(
                  (element) => element.type == models.ItemType.file,
                ) &&
                selected.every(
                  (element) => !downloading.contains(element),
                ))
              IconButton(
                icon: const Icon(FluentIcons.download),
                onPressed: downloadSelectedItems,
              ),
          ],
        );
      },
    );
  }

  Widget buildContent(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    return FutureBuilder<models.Items>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final models.Items items = snapshot.data!;
          return GridView.builder(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: width,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: items.items.length,
            itemBuilder: (context, index) {
              final models.Item item = items.items[index];
              return FlyoutTarget(
                controller: controller,
                child: HoverButton(
                  onLongPress: selected.isEmpty
                      ? () => setState(() => selected.contains(item)
                          ? selected.remove(item)
                          : selected.add(item))
                      : null,
                  onPressed: selected.isEmpty
                      ? () => _showFlyout(item)
                      : () => setState(() => selected.contains(item)
                          ? selected.remove(item)
                          : selected.add(item)),
                  builder: (context, states) => FocusBorder(
                    focused: states.isFocused,
                    renderOutside: false,
                    child: RepaintBoundary(
                      child: AnimatedContainer(
                        duration:
                            FluentTheme.of(context).fasterAnimationDuration,
                        decoration: BoxDecoration(
                          color: selected.contains(item)
                              ? ButtonThemeData.checkedInputColor(
                                  FluentTheme.of(context),
                                  states,
                                )
                              : ButtonThemeData.uncheckedInputColor(
                                  FluentTheme.of(context),
                                  states,
                                  transparentWhenNone: true,
                                ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            (() {
                              switch (item.type) {
                                case models.ItemType.file:
                                  return const Icon(FluentIcons.page, size: 50);
                                case models.ItemType.folder:
                                  return const Icon(FluentIcons.folder,
                                      size: 50);
                                case models.ItemType.link:
                                  return const Icon(FluentIcons.page_link,
                                      size: 50);
                              }
                            })(),
                            Padding(
                              padding: const EdgeInsetsDirectional.only(top: 8),
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.fade,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        } else if (snapshot.hasError) {
          if (snapshot.error.runtimeType == FetchDataException ||
              snapshot.error.runtimeType == NoConnectivityException) {
            return const Center(
              child: Text("Something went wrong, check wi-fi connection."),
            );
          } else {
            final models.Error error = snapshot.error as models.Error;
            return Center(child: Text(error.message));
          }
        } else {
          return Center(
            child: SizedBox.square(
              dimension: mediaQueryData.size.width < mediaQueryData.size.height
                  ? mediaQueryData.size.width / 4
                  : mediaQueryData.size.height / 4,
              child: const ProgressRing(),
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    _future = _getItems();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        padding: EdgeInsets.zero,
        header: buildHeader(context),
        content: buildContent(context),
      );
}
