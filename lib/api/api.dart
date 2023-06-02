library api;

import 'dart:io';
import 'dart:convert' show utf8;

import 'package:creative_project_client_flutter/database.dart';
import 'package:http/http.dart' as http;

import 'models/models.dart' as models;
import 'exceptions.dart';

class API {
  static API? _instance;
  final http.Client client;

  const API._({required this.client});

  factory API() => _instance!;

  static Future<void> init() async {
    if (_instance != null) return;
    _instance = API._(client: http.Client());
  }

  Future<String> getLocalIP() async {
    for (NetworkInterface interface in await NetworkInterface.list()) {
      for (var address in interface.addresses.map((e) => e.address)) {
        if (address.startsWith('192.168')) return address;
      }
    }
    throw NoConnectivityException("fail to get local ip");
  }

  Future<models.Response<T>> _request<T>(
    String path, {
    String? ip,
    Map<String, dynamic>? queryParameters,
  }) async {
    // Параметры каждый раз получаются заново просто потому что так проще
    // проверить, подключено ли устройство к сети.
    ip ??= await getLocalIP();
    int port = Database().port;

    return _parseResponse<T>(
      await client.get(Uri.http("$ip:$port", path, queryParameters)),
    );
  }

  models.Response<T> _parseResponse<T>(http.Response response) {
    switch (response.statusCode) {
      case 200:
        return models.ResponseSerializer<T>()
            .fromJson(utf8.decode(response.bodyBytes));
    }
    throw FetchDataException('StatusCode : ${response.statusCode}');
  }

  Future<models.Data> list([String? ip]) async {
    models.Response<models.Data> response = await _request<models.Data>(
      '/list',
      ip: ip,
    );
    if (response.ok) {
      return response.data!;
    } else {
      throw InvalidInputException("${response.err!.code.toRadixString(16)}: "
          "${response.err!.message}");
    }
  }

  Future<bool> add(models.Item item) async {
    Map<String, dynamic> queryParameters = models.ItemSerializer().toMap(item);
    models.Response response = await _request(
      '/add',
      queryParameters:
          queryParameters.map((key, value) => MapEntry(key, value.toString())),
    );
    if (response.ok) {
      return true;
    } else {
      throw InvalidInputException("${response.err!.code.toRadixString(16)}: "
          "${response.err!.message}");
    }
  }

  Future<bool> del(String title) async {
    models.Response response = await _request(
      '/del',
      queryParameters: {"title": models.b64enc(title)},
    );
    if (response.ok) {
      return true;
    } else {
      throw InvalidInputException("${response.err!.code.toRadixString(16)}: "
          "${response.err!.message}");
    }
  }

  Future<models.Online> online() async {
    models.Response<models.Online> response = await _request<models.Online>(
      '/online',
    );
    if (response.ok) {
      return response.data!;
    } else {
      throw InvalidInputException("${response.err!.code.toRadixString(16)}: "
          "${response.err!.message}");
    }
  }

  Future<bool> shutdown(String title) async {
    models.Response response = await _request('/shutdown');
    if (response.ok) {
      return true;
    } else {
      throw InvalidInputException("${response.err!.code.toRadixString(16)}: "
          "${response.err!.message}");
    }
  }
}
