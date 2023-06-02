// на medium.com нашел хороишй пример обработки статус кода
// https://medium.com/solidmvp-africa/making-your-api-calls-in-flutter-the-right-way-f0a03e35b4b1

class AppException implements Exception {
  final String message;
  final String prefix;

  AppException({required this.message, required this.prefix});

  @override
  String toString() => "$prefix$message";
}

class FetchDataException extends AppException {
  FetchDataException(String message)
      : super(message: message, prefix: "Error During Communication: ");
}

// class BadRequestException extends AppException {
//   BadRequestException(String message)
//       : super(message: message, prefix: "Invalid Request: ");
// }

// class UnauthorisedException extends AppException {
//   UnauthorisedException(String message)
//       : super(message: message, prefix: "Unauthorised: ");
// }

class InvalidInputException extends AppException {
  InvalidInputException(String message)
      : super(message: message, prefix: "Invalid Input: ");
}

class NoConnectivityException extends AppException {
  NoConnectivityException(String message)
      : super(message: message, prefix: "No Connectivity: ");
}
