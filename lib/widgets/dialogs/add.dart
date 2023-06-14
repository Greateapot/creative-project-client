import 'package:fluent_ui/fluent_ui.dart';

import 'package:file_selector/file_selector.dart';
import 'package:api/models.dart' as models;

import '../../2i18nEx.dart';
import '../../utils.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late final TextEditingController titleController;
  late final TextEditingController pathController;
  late models.ItemType type;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    pathController = TextEditingController();
    type = models.ItemType.file;
  }

  @override
  void dispose() {
    titleController.dispose();
    pathController.dispose();
    super.dispose();
  }

  void save(BuildContext context) {
    Navigator.of(context).pop(models.Item(
      title: titleController.text,
      type: type,
      path: pathController.text,
    ));
  }

  void pickFile(BuildContext context) async {
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[]);
    if (file != null) {
      setState(() {
        pathController.text = file.path;
        titleController.text = file.path.split('/').last;
      });
    }
  }

  void pickDirectory(BuildContext context) async {
    final String? directoryPath = await getDirectoryPath();
    if (directoryPath != null) {
      setState(() => pathController.text = directoryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: (() {
        switch (type) {
          case models.ItemType.file:
            return const Text(addItemDialogTitleFile);
          case models.ItemType.folder:
            return const Text(addItemDialogTitleDirectory);
          case models.ItemType.link:
            return const Text(addItemDialogTitleURL);
        }
      })(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ComboBox<models.ItemType>(
                value: type,
                items: models.ItemType.values
                    .map((e) => ComboBoxItem(
                          value: e,
                          child: Text(e.name), // TODO: string/map by val + i18n
                        ))
                    .toList(),
                onChanged: (models.ItemType? t) => setState(() => type = t!),
              ),
              if (type == models.ItemType.file)
                Button(
                  child: const Text(addItemDialogPickFilePath),
                  onPressed: () => pickFile(context),
                ),
              if (type == models.ItemType.folder)
                Button(
                  child: const Text(addItemDialogPickDirectoryPath),
                  onPressed: () => pickDirectory(context),
                ),
            ],
          ),
          TextFormBox(
            controller: pathController,
            placeholder: addItemDialogPathControllerPlaceHolder,
            readOnly: type != models.ItemType.link,
            validator: (value) => value == null || value.isEmpty
                ? addItemDialogPathControllerValidator
                : null,
            onChanged: (value) => setState(() {}),
          ),
          TextFormBox(
            controller: titleController,
            placeholder: addItemDialogTitleControllerPlaceHolder,
            validator: (value) => value == null || value.isEmpty
                ? addItemDialogTitleControllerValidator
                : null,
            onChanged: (value) => setState(() {}),
          ),
        ]
            .map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: e,
                ))
            .toList(),
      ),
      actions: [
        Button(
          onPressed: (titleController.text.isNotEmpty &&
                  pathController.text.isNotEmpty &&
                  isURL(pathController.text))
              ? () => save(context)
              : null,
          child: const Text(addItemDialogSave),
        ),
        Button(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(addItemDialogCancel),
        ),
      ],
    );
  }
}
