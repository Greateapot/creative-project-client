part of api.models;

class Data {
  final List<Item> items;

  const Data({required this.items});

  @override
  String toString() =>
      "Data#$hashCode(items: ${[for (final Item item in items) '$item, ']})";
}

class DataSerializer extends Serializer<Data> {
  @override
  Data fromMap(Map<String, dynamic> map) => Data(
        items: map['items'] != null
            ? [
                for (final Map<String, dynamic> v in map['items'])
                  ItemSerializer().fromMap(v),
              ]
            : [],
      );

  @override
  Map<String, dynamic> toMap(Data obj) => <String, dynamic>{
        "items": [
          for (final Item item in obj.items) ItemSerializer().toMap(item)
        ],
      };
}
