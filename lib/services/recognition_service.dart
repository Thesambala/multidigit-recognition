import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../config/api_config.dart';

class RecognitionResponse {
  RecognitionResponse({
    required this.prediction,
    required this.accuracy,
    required this.processingTimeMs,
    this.imageUrl,
  });

  final String prediction;
  final double accuracy;
  final int processingTimeMs;
  final String? imageUrl;

  factory RecognitionResponse.fromJson(Map<String, dynamic> json) {
    return RecognitionResponse(
      prediction: json['prediction']?.toString() ?? '---',
      accuracy: (json['accuracy'] ?? 0).toDouble(),
      processingTimeMs: json['processing_time_ms'] ?? 0,
      imageUrl: json['image_url']?.toString(),
    );
  }
}

class RecognitionException implements Exception {
  RecognitionException(this.message);

  final String message;

  @override
  String toString() => 'RecognitionException(message: $message)';
}

class RecognitionService {
  static const int _maxUploadBytes = 4 * 1024 * 1024; // 4MB guard

  RecognitionService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.recognitionBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ),
          );

  final Dio _dio;

  Future<RecognitionResponse> submit({
    required Uint8List imageBytes,
    required String captureSource,
    Map<String, dynamic>? cropBox,
    String? deviceId,
  }) async {
    _validateFileSize(imageBytes.lengthInBytes);

    try {
      final fileName = 'capture_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final formData = FormData.fromMap({
        'device_id': deviceId ?? 'frontend-simulator',
        'capture_source': captureSource,
        'timestamp': DateTime.now().toIso8601String(),
        if (cropBox != null) 'crop_box': jsonEncode(cropBox),
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post('/recognitions', data: formData);
      return RecognitionResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (error) {
      throw RecognitionException(_mapDioError(error));
    } catch (error) {
      throw RecognitionException(error.toString());
    }
  }

  String _mapDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Tidak dapat terhubung ke server. Pastikan backend sedang berjalan.';
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Permintaan timeout. Mohon coba lagi.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        final detail = _extractDetail(error.response?.data);
        if (status >= 500) {
          return 'Server mengalami gangguan. Coba lagi nanti.';
        }
        return detail ?? 'Permintaan ditolak (kode $status).';
      case DioExceptionType.cancel:
        return 'Permintaan dibatalkan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat server tidak valid.';
    }
  }

  String? _extractDetail(dynamic data) {
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    return null;
  }

  void _validateFileSize(int size) {
    if (size == 0) {
      throw RecognitionException('Gambar tidak boleh kosong.');
    }
    if (size > _maxUploadBytes) {
      final sizeMb = (size / (1024 * 1024)).toStringAsFixed(1);
      final maxMb = (_maxUploadBytes / (1024 * 1024)).toStringAsFixed(1);
      throw RecognitionException(
        'Ukuran file $sizeMb MB melebihi batas $maxMb MB. Mohon perkecil gambar.',
      );
    }
  }
}
