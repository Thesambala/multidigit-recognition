import 'package:flutter/material.dart';
import 'scan_page.dart';

class DetectionPage extends StatelessWidget {
  const DetectionPage({super.key});

  void _onStartDetection(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Judul
              const Text(
                'Deteksi Multidigit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Deskripsi
              const Text(
                'Mengenali angka yang terdiri dari beberapa digit sekaligus langsung dari kamera. Membantu pembacaan angka secara cepat, otomatis, dan konsisten.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.6,
                ),
              ),

              const Spacer(),

              // Ilustrasi kamera dengan scanner frame
              Center(
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Icon kamera
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 80,
                        color: Color(0xFF1E88E5),
                      ),
                      // Scanner frame corners
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _buildCorner(isTop: true, isLeft: true),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _buildCorner(isTop: true, isLeft: false),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: _buildCorner(isTop: false, isLeft: true),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: _buildCorner(isTop: false, isLeft: false),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Tombol Mulai Deteksi
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _onStartDetection(context),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Mulai Deteksi Multidigit',
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: Color(0xFF1E88E5), width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: Color(0xFF1E88E5), width: 4)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: Color(0xFF1E88E5), width: 4)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: Color(0xFF1E88E5), width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}