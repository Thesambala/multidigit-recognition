import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/capture_provider.dart';
import '../services/recognition_service.dart';
import '../utils/image_crop_utils.dart';
import 'crop_page.dart';
import 'result_page.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker _picker = ImagePicker();
  final RecognitionService _recognitionService = RecognitionService();
  CameraController? _cameraController;
  Future<void>? _cameraInitFuture;
  bool _isDetected = false;
  bool _isProcessingCapture = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _initializeCameraIfPossible();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CaptureProvider>().clear();
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isDetected = true;
        });
      }
    });
  }

  Future<void> _initializeCameraIfPossible() async {
    if (!_isMobile) return;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        return;
      }
      final CameraDescription camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _cameraController = controller;
      _cameraInitFuture = controller.initialize();
      await _cameraInitFuture;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Tidak dapat menginisialisasi kamera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _openManualCropPage(Uint8List bytes) async {
    final capture = context.read<CaptureProvider>();
    capture.setOriginal(bytes);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CropPage(initialBytes: bytes)),
    );
  }

  Future<void> _onCaptureFromCamera() async {
    if (!_isMobile) {
      _showSnack('Mode kamera hanya tersedia di perangkat seluler.');
      return;
    }
    if (_cameraController == null || _cameraInitFuture == null) {
      _showSnack('Kamera belum siap.');
      return;
    }
    if (_isProcessingCapture) return;

    setState(() => _isProcessingCapture = true);

    try {
      await _cameraInitFuture;
      final file = await _cameraController!.takePicture();
      final bytes = await file.readAsBytes();
      await _processAutoCapture(bytes);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengambil gambar: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessingCapture = false);
      }
    }
  }

  Future<void> _onPickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        await _openManualCropPage(bytes);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Gagal mengakses galeri: $e');
    }
  }

  Future<void> _processAutoCapture(Uint8List originalBytes) async {
    final capture = context.read<CaptureProvider>();
    capture
      ..setOriginal(originalBytes)
      ..setError(null)
      ..setCaptureSource('Tangkapan Kamera');

    final autoResult = ImageCropUtils.autoCropToAspect(originalBytes);
    final Uint8List payloadBytes = autoResult?.bytes ?? originalBytes;
    capture.setCropped(payloadBytes);
    capture.setUploading(true);

    try {
      final response = await _recognitionService.submit(
        imageBytes: payloadBytes,
        captureSource: 'camera-auto',
        cropBox: autoResult?.cropBox,
      );
      capture.setPrediction(response.prediction, response.accuracy);

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            imageBytes: payloadBytes,
            detectedNumber: response.prediction,
            accuracy: response.accuracy,
          ),
        ),
      );
    } on RecognitionException catch (error) {
      capture.setError(error.message);
      _showSnack(
        error.message,
        onRetry: () => _processAutoCapture(originalBytes),
      );
    } catch (error) {
      capture.setError(error.toString());
      _showSnack(
        'Gagal mengirim gambar.',
        onRetry: () => _processAutoCapture(originalBytes),
      );
    } finally {
      capture.setUploading(false);
    }
  }

  void _showSnack(String message, {VoidCallback? onRetry}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
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
      backgroundColor: const Color(0xFF2D2D2D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D2D2D),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scan Multidigit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'From your camera or a picture',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      _buildCameraSurface(),
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final size = Size(
                                constraints.maxWidth,
                                constraints.maxHeight,
                              );
                              final frameRect = _buildOverlayRect(size);
                              return CustomPaint(
                                painter: ScannerFramePainter(
                                  color: _isDetected
                                      ? Colors.green
                                      : Colors.grey,
                                  frameRect: frameRect,
                                ),
                                child: const SizedBox.expand(),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isDetected)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Deteksi!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Ambil Foto',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _onPickFromGallery,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white54, width: 2),
                          color: Colors.grey[800],
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    GestureDetector(
                      onTap: _isProcessingCapture ? null : _onCaptureFromCamera,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isProcessingCapture
                                ? Colors.white24
                                : Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isProcessingCapture
                                ? Colors.white24
                                : Colors.white,
                          ),
                          child: _isProcessingCapture
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    const SizedBox(width: 50, height: 50),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (isUploading) _buildUploadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildCameraSurface() {
    if (!_isMobile) {
      return _buildPlaceholder(
        'Camera preview tersedia di Android/iOS. Gunakan galeri untuk menguji di platform ini.',
      );
    }
    if (_cameraInitFuture == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return FutureBuilder<void>(
      future: _cameraInitFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return _buildPlaceholder('Kamera gagal dimuat.');
        }
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          return _buildPlaceholder('Kamera belum siap.');
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CameraPreview(_cameraController!),
        );
      },
    );
  }

  Widget _buildPlaceholder(String message) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
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
              'Mengirim gambar ke server...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Rect _buildOverlayRect(Size size) {
    const aspectRatio = 3.0;
    double width = size.width;
    double height = width / aspectRatio;

    if (height > size.height) {
      height = size.height;
      width = height * aspectRatio;
    }

    final left = (size.width - width) / 2;
    final top = (size.height - height) / 2;
    return Rect.fromLTWH(left, top, width, height);
  }
}

class ScannerFramePainter extends CustomPainter {
  final Color color;
  final Rect frameRect;

  const ScannerFramePainter({required this.color, required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final cornerLength = math.min(
      40.0,
      math.min(frameRect.width, frameRect.height) / 3,
    );
    const radius = 8.0;

    canvas.drawPath(
      Path()
        ..moveTo(frameRect.left, frameRect.top + cornerLength)
        ..lineTo(frameRect.left, frameRect.top + radius)
        ..quadraticBezierTo(
          frameRect.left,
          frameRect.top,
          frameRect.left + radius,
          frameRect.top,
        )
        ..lineTo(frameRect.left + cornerLength, frameRect.top),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(frameRect.right - cornerLength, frameRect.top)
        ..lineTo(frameRect.right - radius, frameRect.top)
        ..quadraticBezierTo(
          frameRect.right,
          frameRect.top,
          frameRect.right,
          frameRect.top + radius,
        )
        ..lineTo(frameRect.right, frameRect.top + cornerLength),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(frameRect.left, frameRect.bottom - cornerLength)
        ..lineTo(frameRect.left, frameRect.bottom - radius)
        ..quadraticBezierTo(
          frameRect.left,
          frameRect.bottom,
          frameRect.left + radius,
          frameRect.bottom,
        )
        ..lineTo(frameRect.left + cornerLength, frameRect.bottom),
      paint,
    );

    canvas.drawPath(
      Path()
        ..moveTo(frameRect.right - cornerLength, frameRect.bottom)
        ..lineTo(frameRect.right - radius, frameRect.bottom)
        ..quadraticBezierTo(
          frameRect.right,
          frameRect.bottom,
          frameRect.right,
          frameRect.bottom - radius,
        )
        ..lineTo(frameRect.right, frameRect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerFramePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.frameRect != frameRect;
  }
}
