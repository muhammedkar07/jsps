import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class LessonTopicScreen extends StatefulWidget {
  final String category;
  const LessonTopicScreen({super.key, required this.category});

  @override
  State<LessonTopicScreen> createState() => _LessonTopicScreenState();
}

class _LessonTopicScreenState extends State<LessonTopicScreen> {
  final _service = FirestoreService();
  List<Map<String, dynamic>> _contents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _service.getLessonContentByCategory(widget.category);
    if (!mounted) return;
    setState(() {
      _contents = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.category)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.menu_book_outlined, size: 48, color: scheme.primary),
                  const SizedBox(height: 16),
                  Text(widget.category,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_contents.isEmpty)
                    Text(
                      'Bu kategori için henüz ders içeriği eklenmemiş.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    )
                  else ...[
                    Expanded(
                      child: ListView.builder(
                        itemCount: _contents.length,
                        itemBuilder: (context, index) {
                          final item = _contents[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (item['title'] ?? 'Ders içeriği').toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    (item['content'] ?? '').toString(),
                                    style: const TextStyle(height: 1.6),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
