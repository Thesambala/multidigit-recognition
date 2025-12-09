import 'package:flutter/material.dart';

import 'detection_page.dart';
import 'profile_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  bool _isTeamExpanded = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: 1.0,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const List<Map<String, String>> _teamMembers = [
    {
      'name': 'Azzahra Attaqina',
      'image': 'assets/images/azza.jpg',
      'role': 'UI/UX Designer, Mobile Developer',
      'class': 'TI-3B',
      'github': 'https://github.com/azzazhr',
    },
    {
      'name': 'Dwi Ahmad Khairy',
      'image': 'assets/images/dwik.JPG',
      'role': 'Project Manager, Mobile Developer',
      'class': 'TI-3B',
      'github': 'https://github.com/Archin0',
    },
    {
      'name': 'Satria Ersa N.',
      'image': 'assets/images/satria.jpg',
      'role': 'Mobile Developer',
      'class': 'TI-3B',
      'github': 'https://github.com/satriaersan',
    },
    {
      'name': 'Tiara Mera Sifa',
      'image': 'assets/images/tiara.png',
      'role': 'Mobile Developer',
      'class': 'TI-3B',
      'github': 'https://github.com/merasifa',
    },
    {
      'name': 'Zilan Zalilan',
      'image': 'assets/images/zilan.png',
      'role': 'UI/UX Designer, Mobile Developer',
      'class': 'TI-3B',
      'github': 'https://github.com/',
    },
  ];

  void _onStartPressed(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DetectionPage()),
    );
  }

  void _toggleTeam() {
    setState(() {
      _isTeamExpanded = !_isTeamExpanded;
      if (_isTeamExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo dari file gambar lokal
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[100],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png', // Ganti dengan path logo Anda
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback jika gambar tidak ditemukan
                      return const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: Color(0xFF1E88E5),
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Judul
              const Text(
                'Deteksi MultiDigit',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              // Deskripsi
              Text(
                'Aplikasi untuk mengenali angka multidigit\nmelalui kamera ataupun unggah foto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              _buildTeamSection(),

              const Spacer(flex: 3),

              // Tombol Mulai
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _onStartPressed(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _toggleTeam,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tim Pengembang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              RotationTransition(
                turns: Tween(begin: 0.0, end: 0.5).animate(_controller),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
        SizeTransition(
          sizeFactor: _animation,
          axisAlignment: -1.0,
          child: Column(
            children: [
              const SizedBox(height: 16),
              // Baris pertama: 2 anggota
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMemberCard(_teamMembers[0]),
                  const SizedBox(width: 16),
                  _buildMemberCard(_teamMembers[1]),
                ],
              ),
              const SizedBox(height: 16),
              // Baris kedua: 3 anggota sisanya
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMemberCard(_teamMembers[2]),
                  const SizedBox(width: 16),
                  _buildMemberCard(_teamMembers[3]),
                  const SizedBox(width: 16),
                  _buildMemberCard(_teamMembers[4]),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, String> member) {
    final name = member['name'] ?? '';
    final imagePath = member['image'] ?? '';
    final role = member['role'] ?? 'Developer';
    final className = member['class'] ?? 'TI-4A';
    final githubUrl = member['github'] ?? 'https://github.com';
    final initial = name.isNotEmpty ? name[0] : '?';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              name: name,
              imagePath: imagePath,
              role: role,
              className: className,
              githubUrl: githubUrl,
            ),
          ),
        );
      },
      child: SizedBox(
        width: 80,
        child: Column(
          children: [
            Hero(
              tag: name,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blueAccent.withOpacity(0.8),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    imagePath,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      color: const Color(0xFFE3F2FD),
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
