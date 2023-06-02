part of api.models;

class Online {
  final List<String> online;

  const Online({required this.online});

  @override
  String toString() => "Online#$hashCode(online: ${[
        for (final String item in online) '$item, '
      ]})";
}

class OnlineSerializer extends Serializer<Online> {
  @override
  Online fromMap(Map<String, dynamic> map) => Online(
        online: <String>[...(map['online'] ?? [])],
      );

  @override
  Map<String, dynamic> toMap(Online obj) => <String, dynamic>{
        "online": obj.online,
      };
}
