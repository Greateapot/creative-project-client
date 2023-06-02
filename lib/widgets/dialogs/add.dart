import 'package:fluent_ui/fluent_ui.dart';

import 'package:file_selector/file_selector.dart';
import 'package:creative_project_client_flutter/api/models/models.dart'
    as models;

import '../../2i18nEx.dart';

enum Type implements Comparable<Type> {
  file(title: addItemDialogTypeFileTitle, value: 1),
  dir(title: addItemDialogTypeDirTitle, value: 2),
  url(title: addItemDialogTypeURLTitle, value: 3);

  const Type({required this.title, required this.value});

  final String title;
  final int value;

  @override
  int compareTo(Type other) => value - other.value;
}

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  late final TextEditingController titleController;
  late final TextEditingController pathController;
  late Type type;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    pathController = TextEditingController();
    type = Type.file;
  }

  @override
  void dispose() {
    titleController.dispose();
    pathController.dispose();
    super.dispose();
  }

  // TODO: assert url with r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
  void save(BuildContext context) {
    Navigator.of(context).pop(models.Item(
      title: titleController.text,
      type: type.value,
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
          case Type.file:
            return const Text(addItemDialogTitleFile);
          case Type.dir:
            return const Text(addItemDialogTitleDirectory);
          case Type.url:
            return const Text(addItemDialogTitleURL);
        }
      })(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ComboBox<Type>(
                value: type,
                items: Type.values
                    .map((e) => ComboBoxItem(
                          value: e,
                          child: Text(e.title),
                        ))
                    .toList(),
                onChanged: (Type? t) => setState(() => type = t!),
              ),
              if (type == Type.file)
                Button(
                  child: const Text(addItemDialogPickFilePath),
                  onPressed: () => pickFile(context),
                ),
              if (type == Type.dir)
                Button(
                  child: const Text(addItemDialogPickDirectoryPath),
                  onPressed: () => pickDirectory(context),
                ),
            ],
          ),
          TextFormBox(
            controller: pathController,
            placeholder: addItemDialogPathControllerPlaceHolder,
            readOnly: type != Type.url,
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
                  pathController.text.isNotEmpty)
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
