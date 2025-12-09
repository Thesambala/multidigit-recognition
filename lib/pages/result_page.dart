import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/capture_provider.dart';
import '../providers/history_provider.dart';

class ResultPage extends StatefulWidget {
  final File? image;
  final Uint8List? imageBytes;
  final String? detectedNumber;
  final double? accuracy;

  const ResultPage({
    super.key,
    this.image,
    this.imageBytes,
    this.detectedNumber,
    this.accuracy,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final capture = context.watch<CaptureProvider>();
    final history = context.watch<HistoryProvider>();
    final Uint8List? previewBytes = widget.imageBytes ?? capture.croppedBytes;
    final displayNumber = widget.detectedNumber ?? capture.prediction ?? '---';
    final displayAccuracy = widget.accuracy ?? capture.accuracy ?? 0;
    final captureSource = capture.captureSource ?? '-';
    final recordedAt = capture.predictionTimestamp;
    final hasResult = displayNumber != '---';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul
              const Text(
                'Hasil Pengenalan Multidigit',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              // // Deskripsi
              // const Text(
              //   'Mengenali angka yang terdiri dari beberapa digit sekaligus langsung dari kamera. Membantu pembacaan angka secara cepat, otomatis, dan konsisten.',
              //   style: TextStyle(
              //     fontSize: 14,
              //     color: Colors.black54,
              //     height: 1.5,
              //   ),
              // ),

              const SizedBox(height: 24),

              // Gambar hasil scan
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: previewBytes != null
                      ? Image.memory(previewBytes, fit: BoxFit.contain)
                      : widget.image != null
                      ? Image.file(widget.image!, fit: BoxFit.contain)
                      : Center(
                          child: Text(
                            displayNumber,
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Courier',
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Metadata ring
              if (recordedAt != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetaTile('Sumber', captureSource),
                      _buildMetaTile('Diproses', _formatTimestamp(recordedAt)),
                    ],
                  ),
                ),

              if (recordedAt != null) const SizedBox(height: 16),

              // Label Hasil Deteksi
              const Text(
                'Hasil Deteksi:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 8),

              // Angka hasil deteksi
              Text(
                displayNumber,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Divider
              Divider(color: Colors.grey[300], thickness: 1),

              const SizedBox(height: 16),

              // Akurasi Deteksi
              const Text(
                'Akurasi Deteksi:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 12),

              // Progress bar akurasi
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (displayAccuracy.clamp(0, 100)) / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          displayAccuracy >= 80
                              ? Colors.green
                              : displayAccuracy >= 50
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${displayAccuracy.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Tombol Scan Lagi
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: hasResult ? () => Navigator.pop(context) : null,
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Scan Lagi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

              const SizedBox(height: 16),

              // Tombol Simpan ke Riwayat
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: hasResult && !_isSaving && !history.isSaving
                      ? () => _saveToHistory(
                          previewBytes,
                          displayNumber,
                          displayAccuracy,
                          captureSource,
                          recordedAt,
                        )
                      : null,
                  icon: const Icon(Icons.save, color: Color(0xFF1E88E5)),
                  label: const Text(
                    'Simpan ke Riwayat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1E88E5), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime time) {
    final local = time.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$date $hour:$minute';
  }

  Future<void> _saveToHistory(
    Uint8List? previewBytes,
    String prediction,
    double accuracy,
    String captureSource,
    DateTime? recordedAt,
  ) async {
    if (previewBytes == null || recordedAt == null) {
      _showSnack('Gambar atau waktu deteksi tidak tersedia.');
      return;
    }

    setState(() => _isSaving = true);
    final history = context.read<HistoryProvider>();

    try {
      await history.saveEntry(
        imageBytes: previewBytes,
        prediction: prediction,
        accuracy: accuracy,
        captureSource: captureSource,
        recordedAt: recordedAt,
      );
      if (!mounted) return;
      _showSnack('Disimpan ke riwayat.');
    } catch (error) {
      _showSnack('Gagal menyimpan riwayat: $error');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
