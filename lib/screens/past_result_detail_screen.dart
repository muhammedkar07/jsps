import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'lesson_topic_screen.dart';

class PastResultDetailScreen extends StatelessWidget {
  final Map<String, dynamic> result;
  const PastResultDetailScreen({super.key, required this.result});

  String _formatDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      final hh = d.hour.toString().padLeft(2, '0');
      final min = d.minute.toString().padLeft(2, '0');
      return '$dd.$mm.${d.year}  $hh:$min';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalCorrect = result['totalCorrect'] ?? 0;
    final totalWrong = result['totalWrong'] ?? 0;

    // categoryBreakdown: { "Kategori": {"correct": 3, "wrong": 1}, ... }
    final rawBreakdown = result['categoryBreakdown'] as Map<String, dynamic>? ?? {};
    final breakdown = rawBreakdown.map((key, value) {
      final map = value as Map<String, dynamic>;
      return MapEntry(key, {
        'correct': (map['correct'] ?? 0) as int,
        'wrong': (map['wrong'] ?? 0) as int,
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Sınav Detayı')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(_formatDate(result['createdAt']),
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: scheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatBox(label: 'Doğru', value: totalCorrect, color: Colors.green),
                  const SizedBox(width: 24),
                  _StatBox(label: 'Yanlış', value: totalWrong, color: Colors.red),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Konu Bazlı Sonuçlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...breakdown.entries.map((entry) {
            final correct = entry.value['correct']!;
            final wrong = entry.value['wrong']!;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('$correct doğru / $wrong yanlış',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonTopicScreen(category: entry.key),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book_outlined, size: 18),
                      label: const Text('Konu Anlatımı'),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final int value;
  final String label;
  final Color color;
  const _StatBox({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$value',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(label),
      ],
    );
  }
}
