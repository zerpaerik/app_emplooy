import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_storage.dart';

/// Provider de idioma usando Riverpod
final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier() : super(const Locale('en')) {
    _loadSavedLanguage();
  }

  final _storage = LocalStorage.instance;

  /// Cargar idioma guardado
  Future<void> _loadSavedLanguage() async {
    final languageCode = _storage.getLanguage();
    state = Locale(languageCode);
  }

  /// Cambiar idioma
  Future<void> changeLanguage(String languageCode) async {
    state = Locale(languageCode);
    await _storage.saveLanguage(languageCode);
  }

  /// Obtener código de idioma actual
  String get currentLanguageCode => state.languageCode;

  /// Verificar si es inglés
  bool get isEnglish => state.languageCode == 'en';

  /// Verificar si es español
  bool get isSpanish => state.languageCode == 'es';
}
