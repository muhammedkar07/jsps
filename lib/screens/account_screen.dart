import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/app_bottom_nav.dart';

class _AccountData {
  final Map<String, dynamic> profile;
  final List<Map<String, dynamic>> results;

  const _AccountData({required this.profile, required this.results});
}

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<_AccountData> _loadAccountData(User user) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final profile = doc.data() ?? {};
    final results = await FirestoreService().getUserResults(user.uid);
    return _AccountData(profile: profile, results: results);
  }

  String _formatDate(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    if (value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
    }
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    return 'Belirtilmemiş';
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Çıkış yap?'),
            content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('İptal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldLogout) return;

    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Çıkış yapılırken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final scheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesabım')),
        body: const Center(child: Text('Giriş yapılmamış.')),
      );
    }

    return FutureBuilder<_AccountData>(
      future: _loadAccountData(user),
      builder: (context, snapshot) {
        final profile = snapshot.data?.profile ?? {};
        final results = snapshot.data?.results ?? const <Map<String, dynamic>>[];

        final profileFullName = (profile['fullName'] ?? '').toString().trim();
        final firstName = (profile['firstName'] ?? '').toString().trim();
        final lastName = (profile['lastName'] ?? '').toString().trim();
        final fallbackDisplayName = (user.displayName ?? '').toString().trim();
        final fullName = profileFullName.isNotEmpty
            ? profileFullName
            : [firstName, lastName, fallbackDisplayName]
                .where((part) => part.isNotEmpty)
                .join(' ');
        final birthDate = _formatDate(profile['birthDate'] ?? profile['dateOfBirth']);
        final email = (profile['email'] ?? user.email ?? '').toString().trim();

        final totalCorrect = results.fold<int>(0, (total, item) {
          final value = (item['totalCorrect'] ?? 0) as num;
          return total + value.toInt();
        });
        final totalWrong = results.fold<int>(0, (total, item) {
          final value = (item['totalWrong'] ?? 0) as num;
          return total + value.toInt();
        });
        final solvedQuestions = totalCorrect + totalWrong;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Hesabım'),
            actions: [
              IconButton(
                onPressed: () => _confirmSignOut(context),
                icon: const Icon(Icons.logout_outlined),
                tooltip: 'Çıkış Yap',
              ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.tertiary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: Colors.white.withValues(alpha: 0.18),
                            child: const Icon(Icons.person, size: 38, color: Colors.white),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            fullName.isNotEmpty ? fullName : 'Kullanıcı',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            email.isNotEmpty ? email : (user.email ?? 'E-posta yok'),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                      children: [
                        _StatCard(label: 'Çözülen', value: solvedQuestions.toString(), color: Colors.blue),
                        _StatCard(label: 'Doğru', value: totalCorrect.toString(), color: Colors.green),
                        _StatCard(label: 'Yanlış', value: totalWrong.toString(), color: Colors.red),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.badge_outlined,
                              label: 'Ad Soyad',
                              value: fullName.isNotEmpty ? fullName : 'Belirtilmemiş',
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.cake_outlined,
                              label: 'Doğum Tarihi',
                              value: birthDate,
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.email_outlined,
                              label: 'E-posta',
                              value: email.isNotEmpty ? email : 'Belirtilmemiş',
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.quiz_outlined,
                              label: 'Çözülen Toplam Soru',
                              value: solvedQuestions.toString(),
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.check_circle_outline,
                              label: 'Toplam Doğru',
                              value: totalCorrect.toString(),
                            ),
                            const Divider(),
                            _InfoRow(
                              icon: Icons.cancel_outlined,
                              label: 'Toplam Yanlış',
                              value: totalWrong.toString(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: 2,
            onMenuTap: () {},
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
