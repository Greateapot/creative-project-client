library api.models;

import 'dart:convert' show json, base64;

part 'data.dart';
part 'item.dart';
part 'error.dart';
part 'response.dart';
part 'online.dart';

String b64enc(String source) {
  return base64
      .encode(source.codeUnits)
      .replaceAll('+', '.')
      .replaceAll('/', '_')
      .replaceAll('=', '-');
}

String b64dec(String source) {
  return String.fromCharCodes(base64.decode(
    source.replaceAll('.', '+').replaceAll('_', '/').replaceAll('-', '='),
  ));
}

Serializer serializer<T>() {
  switch (T) {
    case Item:
      return ItemSerializer();
    case Data:
      return DataSerializer();
    case Error:
      return ErrorSerializer();
    case Response:
      return ResponseSerializer();
    case Online:
      return OnlineSerializer();
  }
  throw Exception("Serializer for type $T not found");
}

abstract class Serializer<T> {
  String toJson(T obj) => json.encode(toMap(obj));

  Map<String, dynamic> toMap(T obj);

  T fromJson(String source) => fromMap(json.decode(source));

  T fromMap(Map<String, dynamic> map);
}
