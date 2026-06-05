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
  static const _iptvHostKey = 'iptv_host';
  static const _iptvUsernameKey = 'iptv_username';
  static const _iptvPasswordKey = 'iptv_password';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
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
    String iptvHost = '',
    String iptvUsername = '',
    String iptvPassword = '',
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _nameKey, value: name);
    await _storage.write(key: _usernameKey, value: username);
    await _storage.write(key: _m3uUrlKey, value: m3uUrl);
    await _storage.write(key: _expiresAtKey, value: expiresAt);
    await _storage.write(key: _statusKey, value: status);
    await _storage.write(key: _planKey, value: plan);
    await _storage.write(key: _iptvHostKey, value: iptvHost);
    await _storage.write(key: _iptvUsernameKey, value: iptvUsername);
    await _storage.write(key: _iptvPasswordKey, value: iptvPassword);
  }

  Future<String?> getToken() async => _storage.read(key: _tokenKey);
  Future<String?> getUserId() async => _storage.read(key: _userIdKey);
  Future<String?> getName() async => _storage.read(key: _nameKey);
  Future<String?> getUsername() async => _storage.read(key: _usernameKey);
  Future<String?> getM3uUrl() async => _storage.read(key: _m3uUrlKey);
  Future<String?> getExpiresAt() async => _storage.read(key: _expiresAtKey);
  Future<String?> getStatus() async => _storage.read(key: _statusKey);
  Future<String?> getPlan() async => _storage.read(key: _planKey);
  Future<String?> getIptvHost() async => _storage.read(key: _iptvHostKey);
  Future<String?> getIptvUsername() async => _storage.read(key: _iptvUsernameKey);
  Future<String?> getIptvPassword() async => _storage.read(key: _iptvPasswordKey);

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _nameKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _m3uUrlKey);
    await _storage.delete(key: _expiresAtKey);
    await _storage.delete(key: _statusKey);
    await _storage.delete(key: _planKey);
    await _storage.delete(key: _iptvHostKey);
    await _storage.delete(key: _iptvUsernameKey);
    await _storage.delete(key: _iptvPasswordKey);
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
