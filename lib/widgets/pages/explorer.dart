import 'package:fluent_ui/fluent_ui.dart';
import 'package:creative_project_client/widgets/dialogs/add.dart';
import 'package:api/api.dart';
import 'package:api/models.dart' as models;

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
  final double width = 150; // cfg load; mv to ctrl
  final API api = API(); // singleton-service
  models.Data? data;

  bool isUpdating = false;

  List<models.Item> selected = [];

  SortType sortType = SortType.az;

  void sort() {
    if (data == null) return;
    final List<models.Item> files = data!.items
        .where((element) => element.type == models.ItemType.file)
        .toList(growable: false);
    final List<models.Item> folders = data!.items
        .where((element) => element.type == models.ItemType.folder)
        .toList(growable: false);
    final List<models.Item> links = data!.items
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

    setState(() => data = models.Data(items: [...folders, ...files, ...links]));
  }

  void update() async {
    if (isUpdating) return; // atomic-like

    setState(() => isUpdating = true);

    try {
      data = await api.list(widget.ip);
      sort();
    } on NoConnectivityException {
      // TODO: show snack bar
    }

    setState(() => isUpdating = false);
  }

  void addNewItem() async {
    models.Item? item = await showDialog(
        context: context,
        builder: (_) => const AddItemDialog(),
        barrierDismissible: true);
    if (item != null) {
      bool result = await api.add(item);
      if (result) update();
    }
  }

  void deleteSelectedItems() async {
    final List<models.Item> err = [];
    for (final models.Item item in selected.toList(/* create copy */)) {
      selected.remove(item);
      if (!await api.del(item.title)) err.add(item);
    }
    // TODO: show snackbar with err items
    update();
  }

  // void downloadItem(models.Item item) {}
  void downloadSelectedItems() {}

  Widget buildHeader(BuildContext context) {
    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text("/"), // TODO: path (for folders)
        ),
        const Spacer(),
        if (selected.isEmpty)
          ComboBox<SortType>(
            items: [
              for (SortType value in SortType.values)
                ComboBoxItem(value: value, child: Text(value.title)),
            ],
            onChanged: (value) {
              if (value != null) {
                sortType = value;
                sort();
              }
            },
            value: sortType,
          ),
        IconButton(
          icon: const Icon(FluentIcons.refresh),
          onPressed: isUpdating ? null : update,
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
            ))
          IconButton(
            icon: const Icon(FluentIcons.download),
            onPressed: downloadSelectedItems,
          ),
      ],
    );
  }

  Widget buildContent(BuildContext context) {
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    if (isUpdating) {
      return Center(
        child: SizedBox.square(
          dimension: mediaQueryData.size.width < mediaQueryData.size.height
              ? mediaQueryData.size.width / 4
              : mediaQueryData.size.height / 4,
          child: const ProgressRing(),
        ),
      );
    } else if (data != null) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: width,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: data!.items.length,
        itemBuilder: (context, index) => ExplorerItem(
          width: width,
          item: data!.items[index],
          isSelected: selected.contains(data!.items[index]),
          onLongPress: selected.isEmpty
              ? (item) => setState(() => selected.contains(item)
                  ? selected.remove(item)
                  : selected.add(item))
              : null,
          onPressed: selected.isEmpty
              // TODO: call details dialog
              ? (item) => debugPrint("${item.toString()}: "
                  "pressed with empty [selected], call details dialog.")
              : (item) => setState(() => selected.contains(item)
                  ? selected.remove(item)
                  : selected.add(item)),
        ),
      );
    } else {
      return const Center(child: Text("Err fetching data"));
    }
  }

  @override
  void initState() {
    update();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        padding: EdgeInsets.zero,
        header: buildHeader(context),
        content: buildContent(context),
      );
}

class ExplorerItem extends StatelessWidget {
  final double width;
  final models.Item item;
  final void Function(models.Item item)? onPressed;
  final void Function(models.Item item)? onLongPress;
  final bool isSelected;

  const ExplorerItem({
    super.key,
    required this.width,
    required this.item,
    required this.isSelected,
    required this.onPressed,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return HoverButton(
      onPressed: onPressed != null ? () => onPressed!(item) : null,
      onLongPress: onLongPress != null ? () => onLongPress!(item) : null,
      builder: (context, states) => FocusBorder(
        focused: states.isFocused,
        renderOutside: false,
        child: RepaintBoundary(
          child: AnimatedContainer(
            duration: FluentTheme.of(context).fasterAnimationDuration,
            decoration: BoxDecoration(
              color: isSelected
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
                      return const Icon(FluentIcons.folder, size: 50);
                    case models.ItemType.link:
                      return const Icon(FluentIcons.page_link, size: 50);
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
    );
  }
}
