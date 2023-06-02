part of api.models;

class Item {
  final String title;
  final String? path;
  final int type;

  const Item({required this.title, required this.type, this.path});

  @override
  String toString() =>
      "Item#$hashCode(title: $title, type: $type, path: $path)";

  @override
  bool operator ==(Object other) {
    if (other.runtimeType == Item) {
      Item v = other as Item;
      return title == v.title && type == v.type && path == v.path;
    }
    return false;
  }

  @override
  int get hashCode => title.hashCode * type + path.hashCode;
}

class ItemSerializer extends Serializer<Item> {
  @override
  Item fromMap(Map<String, dynamic> map) => Item(
        title: b64dec(map['title']),
        path: map['path'] != null ? b64dec(map['path']) : null,
        type: map['type'],
      );

  @override
  Map<String, dynamic> toMap(Item obj) => <String, dynamic>{
        "title": b64enc(obj.title),
        "type": obj.type,
        if (obj.path != null) "path": b64enc(obj.path!),
      };
}
