import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_bottom_nav.dart';
import 'lesson_topic_screen.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _service = FirestoreService();
  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lessonCats = await _service.getLessonCategories();
      final fallbackCats = await _service.getCategories();
      final merged = {...lessonCats, ...fallbackCats}.toList()..sort();

      if (!mounted) return;
      setState(() {
        _categories = merged;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Konu Anlatımı'),
      ),
      drawer: const AppDrawer(),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? const Center(child: Text('Henüz kategori bulunamadı.'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _categories.map((cat) {
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: Icon(Icons.menu_book_outlined, color: scheme.primary),
                        title: Text(cat),
                        subtitle: const Text('Konu anlatımını görüntüle'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LessonTopicScreen(category: cat)),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
