import 'dart:async';

import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = FirestoreService();
  List<String> _categories = [];
  String? _selectedCategory;
  bool _loading = true;
  String? _error;
  late Timer _countdownTimer;
  Duration _timeLeft = const Duration(days: 45, hours: 7);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _timeLeft = _timeLeft - const Duration(seconds: 1);
        if (_timeLeft.inSeconds <= 0) {
          _timeLeft = const Duration();
          _countdownTimer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _service.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startTopicQuiz(String category) async {
    final questions = await _service.getQuestionsByCategory(category);
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bu konuda henüz soru yok.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
    );
  }

  Future<void> _startMockExam() async {
    final count = await _askQuestionCount();
    if (count == null) return;
    final questions = await _service.getRandomExam(count);
    if (!mounted) return;
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Henüz hiç soru eklenmemiş.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuizScreen(questions: questions)),
    );
  }

  Future<int?> _askQuestionCount() {
    final controller = TextEditingController(text: '20');
    return showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kaç soruluk deneme?'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Soru sayısı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final n = int.tryParse(controller.text) ?? 20;
              Navigator.pop(context, n);
            },
            child: const Text('Başla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('JSPS Sınav'),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Bir hata oluştu:\n$_error',
                        textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.timer_rounded, color: Colors.white.withValues(alpha: 0.9)),
                              const SizedBox(width: 8),
                              const Text(
                                'JSPS sınavına geri sayım',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _CountdownChip(value: days.toString(), label: 'gün'),
                              const SizedBox(width: 8),
                              _CountdownChip(value: hours.toString(), label: 'saat'),
                              const SizedBox(width: 8),
                              _CountdownChip(value: minutes.toString(), label: 'dakika'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hoş geldin 👋',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Bugün pratik yapmaya hazır mısın?',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: scheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _startMockExam,
                              icon: const Icon(Icons.timer_outlined),
                              label: const Text('Deneme Sınavı Başlat'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text('Konu Bazlı Çöz',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (_categories.isEmpty)
                      const Text("Henüz kategori bulunamadı, Firestore'a soru ekleyin.")
                    else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: scheme.outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedCategory,
                            hint: const Text('Bir konu seç'),
                            icon: const Icon(Icons.expand_more),
                            items: _categories
                                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedCategory != null)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _startTopicQuiz(_selectedCategory!),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Teste Başla'),
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _CountdownChip extends StatelessWidget {
  final String value;
  final String label;

  const _CountdownChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
