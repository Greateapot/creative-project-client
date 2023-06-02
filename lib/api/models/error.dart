part of api.models;

class Error {
  final int code;
  final String message;

  const Error({required this.code, required this.message});

  @override
  String toString() => "Error#$hashCode(code: $code, message: $message)";

}

class ErrorSerializer extends Serializer<Error> {
  @override
  Error fromMap(Map<String, dynamic> map) => Error(
        code: map['code'],
        message: map['message'],
      );

  @override
  Map<String, dynamic> toMap(Error obj) => <String, dynamic>{
        'code': obj.code,
        'message': obj.message,
      };
}
