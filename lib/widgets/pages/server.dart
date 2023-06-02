import 'dart:io';
import 'dart:ffi' as ffi;

import 'package:path/path.dart' as path;
import 'package:process_utils/process_utils.dart';
import 'package:creative_project_client_flutter/database.dart';
import 'package:fluent_ui/fluent_ui.dart';

const String kServerExeFileName = "creative_project_server.exe"; // TODO: cfg

class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  late final Database database;
  late final ProcessUtils processUtils;

  /// TODO:
  /// 1. methods:
  /// 1.1. run() for start .exe; filename = const; save pid or find by filename;
  /// 1.2. stop() // kill() for kill .exe; by pid or find filename;
  /// 1.3. getPid() for kill()
  /// 2. style:
  ///     (h:40; *STATUS*)
  ///         (stop)
  ///     details: ... (ex: runtime; filename; pid; status (again); ...)
  /// 3. Path to {filename.exe} if its moved or not found by `./`
  /// 4. Call server with args: --host={lip} --port={port} --scanDelay=...
  ///   All from cfg.json; RM cfg.json
  /// 5. Smile ;)

  // void start() async {
  //   Process p = await Process.start(
  //     'creative_project_server.exe',
  //     "--lip=192.168.10.104 --port=8097 --sd=100 --st=8".split(' '),
  //     // TODO: db args
  //   );
  //   database.pid = p.pid;
  // }

  // void stop() async {
  //   Process.killPid(database.pid);
  // }

  @override
  void initState() {
    // linux & android
    var libPath = path.join(Directory.current.path, 'lib_process_utils.so');
    if (Platform.isWindows) {
      libPath = path.join(Directory.current.path, 'lib_process_utils.dll');
    } // win

    processUtils = ProcessUtils(ffi.DynamicLibrary.open(libPath));
    database = Database();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("${processUtils.get_pid_by_name('YourPhone.exe')}"),
    );
  }
}
