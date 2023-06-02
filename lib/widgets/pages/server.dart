import 'dart:io';
import 'dart:ffi' as ffi;

import 'package:path/path.dart' as path;
import 'package:process_utils/process_utils.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:creative_project_client_flutter/database.dart';
import 'package:creative_project_client_flutter/api/api.dart';
import 'package:creative_project_client_flutter/2i18nEx.dart';

const String kServerExeFileName = "creative_project_server.exe";

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late final Database database;
  late final ProcessUtils processUtils;
  late final API api;

  @override
  void initState() {
    // linux & android
    var libPath = path.join(Directory.current.path, 'lib_process_utils.so');
    if (Platform.isWindows) {
      libPath = path.join(Directory.current.path, 'lib_process_utils.dll');
    } // win

    processUtils = ProcessUtils(ffi.DynamicLibrary.open(libPath));
    database = Database();
    api = API();

    super.initState();
  }

  Future<bool> isRunning() async =>
      processUtils.get_pid_by_name(kServerExeFileName) > -1;

  void start() async {
    List<String> argsList = [
      "--lip=${await api.getLocalIP()}",
      "--port=${database.port}",
      "--sd=${database.scanDelay}",
      "--st=${database.scanThreads}",
      "--df=${database.dataFileName}",
      "--cfe=${database.corrupted}",
    ];

    bool ok =
        processUtils.start_by_name(kServerExeFileName, argsList.join(" ")) == 1;

    if (ok) {
      setState(() {});
    } else {
      _showSnackbar("$serverSettingsPageStartError ($kServerExeFileName)");
    }
  }

  void stop() {
    setState(() {
      processUtils.kill_by_name(kServerExeFileName);
    });
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      header: FutureBuilder<bool>(
        future: isRunning(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            bool isRunningV = snapshot.data!;
            return Row(
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(serverSettingsPageStatus),
                ),
                Text(isRunningV
                    ? serverSettingsPageRunning
                    : serverSettingsPageNotRunning),
                const Expanded(child: Spacer()),
                Button(
                  onPressed: isRunningV ? stop : start,
                  child: Text(isRunningV
                      ? serverSettingsPageStop
                      : serverSettingsPageStart),
                ),
                if (isRunningV)
                  Button(
                    onPressed: () {
                      processUtils.kill_by_name(kServerExeFileName);
                      start();
                    },
                    child: const Text(serverSettingsPageReload),
                  ),
              ],
            );
          } else {
            return const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(serverSettingsPageLoading),
            );
          }
        },
      ),
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Text("TODO: логи. Здесь будут выводиться логи сервера, "
              "просто я еще не придумал как реализовать это."),
        ],
      ),
    );
  }
}
