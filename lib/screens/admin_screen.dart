import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _questionFormKey = GlobalKey<FormState>();
  final _categoryController = TextEditingController();
  final _questionController = TextEditingController();
  final _optionControllers = List.generate(4, (_) => TextEditingController());
  final _correctIndexController = TextEditingController(text: '0');

  final _lessonCategoryController = TextEditingController();
  final _lessonTitleController = TextEditingController();
  final _lessonContentController = TextEditingController();

  List<String> _availableCategories = [];
  String? _selectedLessonCategory;
  bool _savingQuestion = false;
  bool _savingLesson = false;
  bool _addingLessonCategory = false;
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await FirestoreService().getLessonCategories();
    if (!mounted) return;
    setState(() {
      _availableCategories = categories;
      if (_availableCategories.isNotEmpty) {
        _selectedLessonCategory = _availableCategories.first;
      }
      _loadingCategories = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _categoryController.dispose();
    _questionController.dispose();
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    _correctIndexController.dispose();
    _lessonCategoryController.dispose();
    _lessonTitleController.dispose();
    _lessonContentController.dispose();
    super.dispose();
  }

  Future<void> _saveQuestion() async {
    final formValid = _questionFormKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final category = _categoryController.text.trim();
    final questionText = _questionController.text.trim();
    final options = _optionControllers.map((controller) => controller.text.trim()).toList();
    final correctIndex = int.tryParse(_correctIndexController.text) ?? 0;

    if (options.any((option) => option.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüm seçenek alanlarını doldurun.')),
      );
      return;
    }

    setState(() => _savingQuestion = true);
    try {
      await FirestoreService().saveQuestion(
        category: category,
        text: questionText,
        options: options,
        correctIndex: correctIndex.clamp(0, 3),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Soru başarıyla eklendi.')),
      );
      _categoryController.clear();
      _questionController.clear();
      for (final controller in _optionControllers) {
        controller.clear();
      }
      _correctIndexController.text = '0';
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Soru eklenirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingQuestion = false);
    }
  }

  Future<void> _saveLessonContent() async {
    final category = _selectedLessonCategory ?? _lessonCategoryController.text.trim();
    final title = _lessonTitleController.text.trim();
    final content = _lessonContentController.text.trim();

    if (category.isEmpty || title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ders adı, konu ve içerik gereklidir.')),
      );
      return;
    }

    setState(() => _savingLesson = true);
    try {
      await FirestoreService().saveLessonContent(
        category: category,
        title: title,
        content: content,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu içeriği kaydedildi.')),
      );
      _lessonTitleController.clear();
      _lessonContentController.clear();
      _lessonCategoryController.clear();
      _selectedLessonCategory = null;
      _loadCategories();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İçerik kaydedilirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _savingLesson = false);
    }
  }

  Future<void> _addLessonCategory() async {
    final category = _lessonCategoryController.text.trim();
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni konu başlığı yazın.')),
      );
      return;
    }

    setState(() => _addingLessonCategory = true);
    try {
      await FirestoreService().saveLessonCategory(category);
      final categories = await FirestoreService().getLessonCategories();
      if (!mounted) return;
      setState(() {
        _availableCategories = categories;
        _selectedLessonCategory = category;
        _lessonCategoryController.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konu başlığı eklendi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konu başlığı eklenirken hata oluştu: $e')),
      );
    } finally {
      if (mounted) setState(() => _addingLessonCategory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Soru Ekle'),
            Tab(text: 'Ders İçeriği'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _questionFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'Konu Başlığı',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Konu başlığı gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _questionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Soru',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty) ? 'Soru gerekli' : null,
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(4, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextFormField(
                        controller: _optionControllers[index],
                        decoration: InputDecoration(
                          labelText: 'Seçenek ${index + 1}',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Seçenek ${index + 1} boş olamaz'
                                : null,
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _correctIndexController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Doğru cevap indexi (0-3)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed < 0 || parsed > 3) {
                        return '0 ile 3 arasında bir değer gir';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _savingQuestion ? null : _saveQuestion,
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(_savingQuestion ? 'Ekleniyor...' : 'Soru Ekle'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _loadingCategories
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedLessonCategory,
                              decoration: InputDecoration(
                                labelText: 'Konu Başlığı',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              items: [
                                ..._availableCategories.map(
                                  (category) => DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedLessonCategory = value;
                                  _lessonCategoryController.text = value ?? '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: _addingLessonCategory ? null : _addLessonCategory,
                            icon: _addingLessonCategory
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.add_circle_outline),
                            tooltip: 'Yeni konu başlığı ekle',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lessonCategoryController,
                        decoration: InputDecoration(
                          labelText: 'Yeni Konu Başlığı',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lessonTitleController,
                        decoration: InputDecoration(
                          labelText: 'Konu',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _lessonContentController,
                        minLines: 10,
                        maxLines: 20,
                        decoration: InputDecoration(
                          labelText: 'Konu anlatımı içeriği',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _savingLesson ? null : _saveLessonContent,
                        icon: const Icon(Icons.save_alt_rounded),
                        label: Text(_savingLesson ? 'Kaydediliyor...' : 'Ders İçeriğini Kaydet'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: scheme.primary,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
