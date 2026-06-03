import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PreferencesStorage {
  static const _storage = FlutterSecureStorage();
  static const _preferredCategoriesKey = 'preferred_categories';
  static const _onboardingCompletedKey = 'preferences_onboarding_completed';

  Future<List<String>> getPreferredCategories() async {
    final raw = await _storage.read(key: _preferredCategoriesKey);

    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! List) return [];

      return decoded
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePreferredCategories(List<String> categories) async {
    final clean = categories
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    await _storage.write(
      key: _preferredCategoriesKey,
      value: jsonEncode(clean),
    );
  }

  Future<void> toggleCategory(String category) async {
    final clean = category.trim();

    if (clean.isEmpty || clean == 'Todos') return;

    final current = await getPreferredCategories();

    if (current.contains(clean)) {
      current.remove(clean);
    } else {
      current.add(clean);
    }

    await savePreferredCategories(current);
  }

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _onboardingCompletedKey);
    return value == 'true';
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _storage.write(
      key: _onboardingCompletedKey,
      value: completed ? 'true' : 'false',
    );
  }

  Future<void> finishOnboarding(List<String> categories) async {
    await savePreferredCategories(categories);
    await setOnboardingCompleted(true);
  }

  Future<void> resetOnboarding() async {
    await _storage.delete(key: _onboardingCompletedKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _preferredCategoriesKey);
    await _storage.delete(key: _onboardingCompletedKey);
  }
}
