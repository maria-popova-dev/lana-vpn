import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String _baseUrl = 'http://94.241.174.24:8080/api/auth';

  final String _vpnUrl = 'http://94.241.174.24:8080/api';

  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<String?> register(String username, String email, String password) async {
    try {
      final response = await _dio.post('$_baseUrl/register', data: {
        'username': username,
        'email': email,
        'password': password,
      });
      return response.data.toString();
    } on DioException catch (e) {
      return 'Код: ${e.response?.statusCode} | Ответ: ${e.response?.data}';
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post('$_baseUrl/login', data: {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        String token = response.data['token'];
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getVpnConfig() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');

      if (token == null) {
        return 'Ошибка: Вы не авторизованы (токен отсутствует)!';
      }

      final response = await _dio.get(
        '$_vpnUrl/vpn/config',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data['config'] as String;
      }
      return 'Не удалось получить конфигурацию';
    } on DioException catch (e) {
      return e.response?.data?.toString() ?? 'Ошибка сети при получении конфига';
    }
  }
}
