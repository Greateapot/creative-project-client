part of api.models;

class Response<T> {
  final bool ok;
  final Error? err;
  final T? data;

  const Response({required this.ok, this.err, this.data});

  @override
  String toString() => "Response#$hashCode(ok: $ok, "
      "err: ${err?.toString()}, data: ${data?.toString()})";
}

class ResponseSerializer<T> extends Serializer<Response<T>> {
  @override
  Response<T> fromMap(Map<String, dynamic> map) => Response<T>(
        ok: map['ok'],
        err: map['err'] != null ? ErrorSerializer().fromMap(map['err']) : null,
        data: map['data'] != null ? serializer<T>().fromMap(map['data']) : null,
      );

  @override
  Map<String, dynamic> toMap(Response<T> obj) => <String, dynamic>{
        "ok": obj.ok,
        if (obj.err != null) "err": ErrorSerializer().toMap(obj.err!),
        if (obj.data != null) "data": serializer<T>().toMap(obj.data!),
      };
}
