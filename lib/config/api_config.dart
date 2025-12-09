class ApiConfig {
  const ApiConfig._();

  /// Ganti IP jika server berjalan di alamat lain.
  static const String recognitionBaseUrl = String.fromEnvironment(
    'RECOGNITION_BASE_URL',
    defaultValue: 'http://192.168.18.62:8000',
  );
}
