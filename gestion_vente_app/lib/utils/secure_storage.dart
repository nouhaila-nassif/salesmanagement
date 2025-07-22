import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureStorage {
  static const _keyToken = 'jwt_token';
  static final _secureStorage = FlutterSecureStorage();

  /// Sauvegarde du token JWT
  static Future<void> saveToken(String token) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } else {
      await _secureStorage.write(key: _keyToken, value: token);
    }
  }

  /// Récupération du token JWT
  static Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyToken);
    } else {
      return await _secureStorage.read(key: _keyToken);
    }
  }

  /// Suppression du token
  static Future<void> deleteToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
    } else {
      await _secureStorage.delete(key: _keyToken);
    }
  }

  /// Décoder la partie payload d'un JWT
  static Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('JWT invalide');
    }

    final payload = parts[1];
    final normalized = base64.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return jsonDecode(decoded);
  }

  /// Récupérer le rôle de l'utilisateur à partir du JWT
  static Future<String?> getUserRole() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final payload = _decodeJwtPayload(token);
      return payload['role'];
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si l'utilisateur est administrateur
  static Future<bool> isAdmin() async {
    final role = await getUserRole();
    return role == "ADMIN"; // Adapter selon le format du backend
  }
}
