import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/question.dart';

class FirestoreService {
  final CollectionReference _questionsRef =
      FirebaseFirestore.instance.collection('questions');
  final CollectionReference _lessonsRef =
      FirebaseFirestore.instance.collection('lesson_contents');
    final CollectionReference _lessonCategoriesRef =
      FirebaseFirestore.instance.collection('lesson_categories');

  // Tüm soruları getirir (kategori filtrelemesi olmadan)
  Future<List<Question>> getAllQuestions() async {
    final snapshot = await _questionsRef.get();
    return snapshot.docs
        .map((doc) => Question.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Belirli bir kategorideki soruları getirir (konu çözme modu için)
  Future<List<Question>> getQuestionsByCategory(String category) async {
    final snapshot =
        await _questionsRef.where('category', isEqualTo: category).get();
    return snapshot.docs
        .map((doc) => Question.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Tüm kategorilerin listesini çıkarır (soruların içinden tekilleştirerek)
  Future<List<String>> getCategories() async {
    final questions = await getAllQuestions();
    final categories = questions.map((q) => q.category).toSet().toList();
    categories.sort();
    return categories;
  }

  // Deneme sınavı için rastgele N soru getirir (tüm kategorilerden karışık)
  Future<List<Question>> getRandomExam(int questionCount) async {
    final allQuestions = await getAllQuestions();
    allQuestions.shuffle();
    if (questionCount >= allQuestions.length) return allQuestions;
    return allQuestions.sublist(0, questionCount);
  }

  // Bir sınav bittiğinde sonucu "results" koleksiyonuna kaydeder
  Future<void> saveExamResult({
    required int totalCorrect,
    required int totalWrong,
    required Map<String, Map<String, int>> categoryBreakdown,
    String? userId,
  }) async {
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('results').add({
      'userId': uid,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'categoryBreakdown': categoryBreakdown,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Geçmiş test sonuçlarını en yeniden en eskiye doğru getirir
  Future<List<Map<String, dynamic>>> getPastResults() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('results')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  Future<List<Map<String, dynamic>>> getUserResults(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('results')
        .where('userId', isEqualTo: uid)
        .get();

    final results = snapshot.docs.map((d) => d.data()).toList();
    results.sort((a, b) {
      final aTime = a['createdAt'] is Timestamp ? (a['createdAt'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b['createdAt'] is Timestamp ? (b['createdAt'] as Timestamp).toDate() : DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return results;
  }

  Future<void> saveQuestion({
    required String category,
    required String text,
    required List<String> options,
    required int correctIndex,
  }) async {
    await _questionsRef.add({
      'category': category.trim(),
      'text': text.trim(),
      'options': options.map((option) => option.trim()).toList(),
      'correctIndex': correctIndex,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveLessonContent({
    required String category,
    required String title,
    required String content,
  }) async {
    await _lessonsRef.add({
      'category': category.trim(),
      'title': title.trim(),
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveLessonCategory(String category) async {
    final normalized = category.trim();
    if (normalized.isEmpty) return;

    final existing = await _lessonCategoriesRef
        .where('name', isEqualTo: normalized)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    await _lessonCategoriesRef.add({
      'name': normalized,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<String>> getLessonCategories() async {
    final snapshots = await Future.wait([
      _lessonCategoriesRef.get(),
      _lessonsRef.get(),
      _questionsRef.get(),
    ]);
    final explicitCategories = snapshots[0].docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['name'] as String?);
    final lessonCategories = snapshots[1].docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
        .whereType<String>();
    final questionCategories = snapshots[2].docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
        .whereType<String>();
    final categories = {
      ...explicitCategories.whereType<String>(),
      ...lessonCategories,
      ...questionCategories,
    }.toList();
    categories.sort();
    return categories;
  }

  Future<List<Map<String, dynamic>>> getLessonContentByCategory(String category) async {
    final snapshot = await _lessonsRef
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: false)
        .get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Duyuruları en yeniden en eskiye doğru getirir
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((d) => d.data()).toList();
  }

  // Kayıt sırasında toplanan ek profil bilgilerini (ad, soyad, doğum tarihi, cinsiyet)
  // kullanıcının Auth kimliğiyle eşleştirerek "users" koleksiyonuna kaydeder
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data, {bool merge = true}) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(uid);
    if (merge) {
      await ref.set(data, SetOptions(merge: true));
      return;
    }
    await ref.set(data);
  }

  Future<void> ensureUserProfileForAuthUser(User user) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await docRef.get();
    final existing = doc.data() ?? {};

    final displayName = (user.displayName ?? '').trim();
    final nameParts = displayName.split(RegExp(r'\s+'));
    final firstName = (existing['firstName'] ?? (nameParts.isNotEmpty ? nameParts.first : '')).toString().trim();
    final lastName = (existing['lastName'] ?? (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '')).toString().trim();
    final email = (existing['email'] ?? user.email ?? '').toString().trim();

    final profile = {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      if (existing['birthDate'] != null) 'birthDate': existing['birthDate'],
      if (existing['gender'] != null) 'gender': existing['gender'],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(profile, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }
}
