import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_download_manager/flutter_download_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:creative_project_client_flutter/widgets/dialogs/add.dart';
import 'package:creative_project_client_flutter/api/api.dart';
import 'package:creative_project_client_flutter/api/models/models.dart'
    as models;
import 'package:creative_project_client_flutter/2i18nEx.dart';

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key, this.ip});

  final String? ip;

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  final DownloadManager dl = DownloadManager();
  final API api = API();

  List<models.Item> selected = [];
  List<models.Item> downloading = [];

  String? status;

  late models.Data value;
  bool refresh = true;

  Future<models.Data> getData() async {
    if (refresh) {
      refresh = false;
      value = await api.list(widget.ip);
    }
    return value;
  }

  void deleteSelectedItems() async {
    final List<String> err = [];
    for (final models.Item item in value.items) {
      if (selected.contains(item)) {
        bool result = await api.del(item.title);
        if (!result) err.add(item.title);
        selected.remove(item);
      }
    }
    if (err.isNotEmpty) {
      _showSnackbar('$itemListDownloadSelectedItemsErr ${err.join(', ')}');
    }
    setState(() => refresh = true);
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

  void deleteItem(models.Item item) async {
    bool result = await api.del(item.title);
    if (!result) {
      _showSnackbar('$itemListDeleteItemErr ${item.title}');
    } else {
      setState(() => refresh = true);
    }
  }

  void addItem() async {
    models.Item? item = await showDialog(
        context: context,
        builder: (_) => const AddItemDialog(),
        barrierDismissible: true);
    if (item != null) {
      bool result = await api.add(item);
      if (result) setState(() => refresh = true);
    }
  }

  void downloadSelectedItems() async {
    for (final models.Item item in selected) {
      downloadItem(item);
    }
    setState(() => selected.clear());
  }

  void downloadItem(models.Item item) async {
    setState(() => downloading.add(item));

    DownloadTask? task = await dl.addDownload(
      (await api.get(item.title, widget.ip)).toString(),
      path.join((await getDownloadsDirectory())!.path, item.title),
    );
    DownloadStatus status = await task!.whenDownloadComplete();
    if (!status.isCompleted) {
      _showSnackbar('$itemListDownloadItemErr ${item.title}');
    }

    setState(() => downloading.remove(item));
  }

  @override
  Widget build(BuildContext context) => ScaffoldPage(
        padding: EdgeInsets.zero,
        header: headerBuilder(context),
        content: FutureBuilder(future: getData(), builder: contentBuilder),
      );

  Widget headerBuilder(BuildContext context) {
    return Row(
      children: [
        if (status != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(status!),
          ),
        const Spacer(),
        // TODO: sort
        const ComboBox<String>(
          items: [
            ComboBoxItem(
              value: "default",
              child: Text("Sort"),
            )
          ],
          value: "default",
        ),
        IconButton(
          onPressed: () => setState(() => refresh = true),
          icon: const Icon(FluentIcons.refresh),
        ),
        if (widget.ip == null)
          IconButton(
            onPressed: addItem,
            icon: const Icon(FluentIcons.add),
          ),
        if (selected.isNotEmpty &&
            selected.every((element) => element.type == selected.first.type))
          (() {
            switch (selected.first.type) {
              case 1: // file
                return IconButton(
                  icon: const Icon(FluentIcons.download),
                  onPressed: downloadSelectedItems,
                );
              case 2: // dir
                return IconButton(
                  icon: const Icon(FluentIcons.folder_open),
                  onPressed: () => _showSnackbar(later),
                );
              case 3: // url
                return IconButton(
                  icon: const Icon(FluentIcons.open_in_new_tab),
                  onPressed: () => _showSnackbar(later),
                );
            }
            return const Icon(FluentIcons.unknown);
          })(),
        if (widget.ip == null && selected.isNotEmpty)
          IconButton(
            onPressed: deleteSelectedItems,
            icon: const Icon(FluentIcons.delete),
          ),
      ],
    );
  }

  Widget contentBuilder(BuildContext context, AsyncSnapshot snapshot) {
    if (snapshot.hasData) {
      models.Data data = snapshot.data!;
      return ListView.builder(
        itemCount: data.items.length,
        itemBuilder: (context, index) {
          models.Item item = data.items[index];
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            child: ListTile.selectable(
                selectionMode: ListTileSelectionMode.multiple,
                selected: selected.contains(item),
                onSelectionChange: (value) => setState(() {
                      if (selected.contains(item)) {
                        selected.remove(item);
                      } else {
                        selected.add(item);
                      }
                    }),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (() {
                      switch (item.type) {
                        case 1:
                          return const Icon(FluentIcons.open_file);
                        case 2:
                          return const Icon(FluentIcons.folder_horizontal);
                        case 3:
                          return const Icon(FluentIcons.file_symlink);
                      }
                      return const Icon(FluentIcons.unknown);
                    })(),
                    const SizedBox(width: 10),
                    Text(item.title),
                  ],
                ),
                subtitle: item.path != null ? Text(item.path!) : null,
                trailing: Row(
                  children: [
                    (() {
                      switch (item.type) {
                        case 1: // file
                          return IconButton(
                            icon: const Icon(FluentIcons.download),
                            onPressed: downloading.contains(item)
                                ? null
                                : () => downloadItem(item),
                          );
                        case 2: // dir
                          return IconButton(
                            icon: const Icon(FluentIcons.folder_open),
                            onPressed: () => _showSnackbar(later),
                          );
                        case 3: // url
                          return IconButton(
                            icon: const Icon(FluentIcons.open_in_new_tab),
                            onPressed: () => _showSnackbar(later),
                          );
                      }
                      return const Icon(FluentIcons.unknown);
                    })(),
                    if (widget.ip == null)
                      IconButton(
                        icon: const Icon(FluentIcons.delete),
                        onPressed: () => deleteItem(item),
                      ),
                  ],
                )),
          );
        },
      );
    } else if (snapshot.hasError) {
      return Center(child: Text(snapshot.error!.toString()));
    } else {
      return const Center(child: ProgressRing());
    }
  }
}
