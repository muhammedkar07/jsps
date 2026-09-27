import 'package:flutter/material.dart';
import '../screens/account_screen.dart';
import '../screens/announcements_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/follow_us_screen.dart';
import '../screens/home_screen.dart';
import '../screens/lessons_screen.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback onMenuTap;

  const AppBottomNav({super.key, required this.currentIndex, required this.onMenuTap});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LessonsScreen()),
            (route) => false,
          );
        } else if (index == 2) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AccountScreen()),
            (route) => false,
          );
        } else if (index == 3) {
          showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (sheetContext) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Geri Bildirim'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FeedbackScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star_outline),
                    title: const Text('Uygulamayı Oyla'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Uygulamayı Oyla'),
                          content: const Text('Uygulama mağazada yayınlandığında buradan oy verebilirsin.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('Tamam'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.campaign_outlined),
                    title: const Text('Duyurular'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const AnnouncementsScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Bizi Takip Et'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const FollowUsScreen()));
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book),
          label: 'Konu Anlatımı',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Hesap',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'Daha Fazla',
        ),
      ],
    );
  }
}
