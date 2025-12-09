import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/capture_provider.dart';
import '../services/recognition_service.dart';
import 'result_page.dart';

class CropPage extends StatefulWidget {
  const CropPage({super.key, required this.initialBytes});

  final Uint8List initialBytes;

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final CropController _cropController = CropController();
  final RecognitionService _recognitionService = RecognitionService();
  bool _isCropping = false;

  void _startCropping() {
    if (_isCropping) return;
    setState(() => _isCropping = true);
    _cropController.crop();
  }

  Future<void> _onCropped(Uint8List bytes) async {
    setState(() => _isCropping = false);
    await _processManualCrop(bytes);
  }

  Future<void> _processManualCrop(Uint8List bytes) async {
    final capture = context.read<CaptureProvider>();
    capture.setCropped(bytes);
    capture
      ..setError(null)
      ..setUploading(true)
      ..setCaptureSource('Galeri - Penyimpanan');

    try {
      final response = await _recognitionService.submit(
        imageBytes: bytes,
        captureSource: 'gallery_manual',
      );

      capture.setPrediction(response.prediction, response.accuracy);

      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imageBytes: bytes,
            detectedNumber: response.prediction,
            accuracy: response.accuracy,
          ),
        ),
      );
    } on RecognitionException catch (error) {
      capture.setError(error.message);
      _showError(error.message, onRetry: () => _processManualCrop(bytes));
    } catch (error) {
      const fallback = 'Terjadi kesalahan saat memproses gambar';
      capture.setError(fallback);
      _showError(fallback, onRetry: () => _processManualCrop(bytes));
    } finally {
      capture.setUploading(false);
    }
  }

  void _showError(String message, {VoidCallback? onRetry}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: onRetry != null
              ? SnackBarAction(label: 'Coba Lagi', onPressed: onRetry)
              : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = context.watch<CaptureProvider>().isUploading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sesuaikan Area Multidigit',
          style: TextStyle(color: Colors.black87, fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Crop(
                      controller: _cropController,
                      image: widget.initialBytes,
                      baseColor: Colors.black,
                      maskColor: Colors.black.withValues(alpha: 0.5),
                      aspectRatio: 3,
                      cornerDotBuilder: (size, index) => Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(size / 2),
                        ),
                      ),
                      onCropped: _onCropped,
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isCropping ? null : _startCropping,
                      icon: _isCropping
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check, color: Colors.white),
                      label: Text(
                        _isCropping ? 'Memproses...' : 'Gunakan Area Ini',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E88E5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (isUploading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Mengirim hasil crop...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
