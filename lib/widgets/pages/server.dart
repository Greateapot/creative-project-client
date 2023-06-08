import 'dart:io';
import 'dart:ffi' as ffi;

import 'package:path/path.dart' as path;
import 'package:process_utils/process_utils.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:api/api.dart';

import '../../database.dart';
import '../../2i18nEx.dart';

const String kServerExeFileName = 'creative_project_server.exe';

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

  void start() {
    List<String> args = [
      '--local-ip="${api.ip}"',
      '--corr-file-ext="${database.corrupted}"',
      '--data-filename="${database.dataFileName}"',
      '--port=${database.port}',
      '--scan-delay=${database.scanDelay}',
      '--scan-threads=${database.scanThreads}',
    ];

    debugPrint("Starting server with args: ${args.join(' ')}");

    if (processUtils.start_by_name(kServerExeFileName, args.join(' ')) == 1) {
      setState(() {});
    } else {
      _showSnackbar('$serverSettingsPageStartError ($kServerExeFileName)');
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
                const Spacer(),
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
          Text('TODO: логи. Здесь будут выводиться логи сервера, '
              'просто я еще не придумал как реализовать это.'),
        ],
      ),
    );
  }
}
