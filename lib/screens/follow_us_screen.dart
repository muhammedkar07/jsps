import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// TODO: Gerçek sosyal medya hesap linklerinle değiştir
const String _instagramUrl = 'https://instagram.com/kullaniciadi';
const String _twitterUrl = 'https://twitter.com/kullaniciadi';
const String _facebookUrl = 'https://facebook.com/kullaniciadi';

class FollowUsScreen extends StatelessWidget {
  const FollowUsScreen({super.key});

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bağlantı açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bizi Takip Et')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.pink),
              title: const Text('Instagram'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, _instagramUrl),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.alternate_email, color: Colors.blue),
              title: const Text('Twitter / X'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, _twitterUrl),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.facebook, color: Colors.indigo),
              title: const Text('Facebook'),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(context, _facebookUrl),
            ),
          ),
        ],
      ),
    );
  }
}
