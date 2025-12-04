import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Riwayat Deteksi'),
        backgroundColor: const Color(0xFF1E88E5),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF1E88E5)),
              title: Text('Deteksi #${index + 1}'),
              subtitle: Text('Hasil: ${1234 + index}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Tampilkan detail
              },
            ),
          );
        },
      ),
    );
  }
}