import 'dart:math';

import 'package:creative_project_client/database.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../2i18nEx.dart';

const int kMinWidthOfLargeScreen = 800;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int scanThreadsValue;
  late final Database database;
  late final List<int> scanThreadsValues;
  late final TextEditingController dataFileNameController;
  late final TextEditingController corruptedController;

  @override
  void initState() {
    database = Database();
    dataFileNameController = TextEditingController(text: database.dataFileName);
    corruptedController = TextEditingController(text: database.corrupted);
    scanThreadsValue = (log(database.scanThreads) ~/ log(2));
    scanThreadsValues = List.generate(
      9,
      (index) => pow(2, index).toInt(),
      growable: false,
    );
    super.initState();
  }

  @override
  void dispose() {
    dataFileNameController.dispose();
    corruptedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    FluentThemeData themeData = FluentTheme.of(context);
    SliderThemeData sliderThemeData = themeData.sliderTheme.merge(
      SliderThemeData(labelBackgroundColor: themeData.accentColor),
    );
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        padding: EdgeInsets.zero,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              settingsPageServerSettingsHeader,
              style: TextStyle(fontSize: 24),
            ),
          ),
          ListTile(
            title: const Text(settingsPagePortTitle),
            subtitle: NumberBox(
              value: database.port,
              min: 8000,
              max: 10000,
              // TODO: MV defaults
              onChanged: (int? v) =>
                  setState(() => database.port = (v ??= 8097)),
              mode: SpinButtonPlacementMode.none,
            ),
          ),
          ListTile(
            title: const Text(settingsPageScanDelayTitle),
            subtitle: Slider(
              label: database.scanDelay.toString(),
              style: sliderThemeData,
              min: 100, // TODO: MV defaults
              max: 3000, // TODO: MV defaults
              divisions: 29,
              value: database.scanDelay.toDouble(),
              onChanged: (v) => setState(() => database.scanDelay = v.toInt()),
            ),
          ),
          ListTile(
            title: const Text(settingsPageScanThreadCountTitle),
            subtitle: Slider(
              label: scanThreadsValues[scanThreadsValue].toString(),
              style: sliderThemeData,
              min: 0, // TODO: MV defaults
              max: 8, // TODO: MV defaults
              divisions: 8,
              value: scanThreadsValue.toDouble(),
              onChanged: (v) => setState(
                () {
                  scanThreadsValue = v.toInt();
                  database.scanThreads = scanThreadsValues[scanThreadsValue];
                },
              ),
            ),
          ),
          ListTile(
            title: const Text(settingsPageDataFileNameTitle),
            subtitle: TextFormBox(
              controller: dataFileNameController,
              validator: (value) => value == null || value.isEmpty
                  ? settingsPageDataFileNameValidator
                  : null,
            ),
            trailing: Column(children: [
              IconButton(
                icon: Icon(
                  FluentIcons.save_as,
                  size: 24,
                  color: themeData.accentColor,
                ),
                onPressed: () {
                  if (dataFileNameController.text.isNotEmpty) {
                    database.dataFileName = dataFileNameController.text;
                  }
                },
              ),
              const Text(
                "save",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
          ),
          ListTile(
            title: const Text(settingsPageCorruptedTitle),
            subtitle: TextFormBox(
              controller: corruptedController,
              validator: (value) => value == null || value.isEmpty
                  ? settingsPageCorruptedValidator
                  : null,
            ),
            trailing: Column(children: [
              IconButton(
                icon: Icon(
                  FluentIcons.save_as,
                  size: 24,
                  color: themeData.accentColor,
                ),
                onPressed: () {
                  if (corruptedController.text.isNotEmpty) {
                    database.dataFileName = corruptedController.text;
                  }
                },
              ),
              const Text(
                "save",
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              settingsPageClientSettingsHeader,
              style: TextStyle(fontSize: 24),
            ),
          ),
          const ListTile(title: Text(later)), // TODO: client settings
        ],
      ),
    );
  }
}
