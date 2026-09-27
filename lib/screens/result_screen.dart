import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/answer_record.dart';
import '../services/firestore_service.dart';

class ResultScreen extends StatefulWidget {
  final List<AnswerRecord> records;
  const ResultScreen({super.key, required this.records});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    final records = widget.records;
    final totalCorrect = records.where((r) => r.isCorrect).length;
    final totalWrong = records.length - totalCorrect;

    final Map<String, Map<String, int>> breakdown = {};
    for (final r in records) {
      breakdown.putIfAbsent(r.category, () => {'correct': 0, 'wrong': 0});
      if (r.isCorrect) {
        breakdown[r.category]!['correct'] = breakdown[r.category]!['correct']! + 1;
      } else {
        breakdown[r.category]!['wrong'] = breakdown[r.category]!['wrong']! + 1;
      }
    }

    try {
      await _service.saveExamResult(
        totalCorrect: totalCorrect,
        totalWrong: totalWrong,
        categoryBreakdown: breakdown,
        userId: FirebaseAuth.instance.currentUser?.uid,
      );
    } catch (_) {
      // Kaydetme başarısız olsa bile kullanıcı sonucu ekranda görmeye devam etsin
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = widget.records;
    final totalCorrect = records.where((r) => r.isCorrect).length;
    final totalWrong = records.length - totalCorrect;

    final Map<String, List<AnswerRecord>> byCategory = {};
    for (final r in records) {
      byCategory.putIfAbsent(r.category, () => []).add(r);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sonuç')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('${records.length} Soru', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatBox(label: 'Doğru', value: totalCorrect, color: Colors.green),
                      const SizedBox(width: 24),
                      _StatBox(label: 'Yanlış', value: totalWrong, color: Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Konu Bazlı Sonuçlar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...byCategory.entries.map((entry) {
            final correct = entry.value.where((r) => r.isCorrect).length;
            final wrong = entry.value.length - correct;
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                title: Text(entry.key),
                trailing: Text('$correct doğru / $wrong yanlış',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text('Ana Sayfaya Dön'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatBox({required this.label, required this.value, required this.color});

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
