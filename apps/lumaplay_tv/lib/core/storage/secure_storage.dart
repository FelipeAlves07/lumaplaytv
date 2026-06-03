import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _nameKey = 'name';
  static const _usernameKey = 'username';
  static const _m3uUrlKey = 'm3u_url';
  static const _expiresAtKey = 'expires_at';
  static const _statusKey = 'status';
  static const _planKey = 'plan';

  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<void> saveSession({
    required String token,
    required String userId,
    required String name,
    required String username,
    required String m3uUrl,
    String expiresAt = '',
    String status = 'ACTIVE',
    String plan = 'Premium',
  }) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    await _storage.write(
      key: _userIdKey,
      value: userId,
    );

    await _storage.write(
      key: _nameKey,
      value: name,
    );

    await _storage.write(
      key: _usernameKey,
      value: username,
    );

    await _storage.write(
      key: _m3uUrlKey,
      value: m3uUrl,
    );

    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt,
    );

    await _storage.write(
      key: _statusKey,
      value: status,
    );

    await _storage.write(
      key: _planKey,
      value: plan,
    );
  }

  Future<String?> getToken() async {
    return await _storage.read(
      key: _tokenKey,
    );
  }

  Future<String?> getUserId() async {
    return await _storage.read(
      key: _userIdKey,
    );
  }

  Future<String?> getName() async {
    return await _storage.read(
      key: _nameKey,
    );
  }

  Future<String?> getUsername() async {
    return await _storage.read(
      key: _usernameKey,
    );
  }

  Future<String?> getM3uUrl() async {
    return await _storage.read(
      key: _m3uUrlKey,
    );
  }

  Future<String?> getExpiresAt() async {
    return await _storage.read(
      key: _expiresAtKey,
    );
  }

  Future<String?> getStatus() async {
    return await _storage.read(
      key: _statusKey,
    );
  }

  Future<String?> getPlan() async {
    return await _storage.read(
      key: _planKey,
    );
  }

  Future<void> clearSession() async {
    // Não usar deleteAll(), porque isso apagaria preferências,
    // onboarding, favoritos locais e continue assistindo.
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _m3uUrlKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _statusKey);
    await _storage.delete(key: _planKey);
  }

  Future<void> clearEverythingForDebug() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final m3uUrl = await getM3uUrl();

    return token != null &&
        token.isNotEmpty &&
        m3uUrl != null &&
        m3uUrl.isNotEmpty;
  }
}
