import 'package:hive/hive.dart';

class Database {
  static const String boxName = "db";
  static Database? _instance;

  Database._({required this.box});

  factory Database() => _instance!;

  final Box box;

  static Future<void> init() async {
    if (_instance != null) return;
    Box box = await Hive.openBox(boxName);
    _instance = Database._(box: box);
  }

  int get port => box.get('port', defaultValue: 8097);
  set port(int value) => box.put('port', value);

  int get scanTimeout => box.get('scanTimeout', defaultValue: 500);
  set scanTimeout(int value) => box.put('scanTimeout', value);

  int get scanThreads => box.get('scanThreads', defaultValue: 4);
  set scanThreads(int value) => box.put('scanThreads', value);

  String get dataFileName => box.get('dataFileName', defaultValue: "data.json");
  set dataFileName(String value) => box.put('dataFileName', value);

  String get corrupted => box.get('corrupted', defaultValue: '.crp');
  set corrupted(String value) => box.put('corrupted', value);
}
