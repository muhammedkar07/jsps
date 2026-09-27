// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('logout action should sign out instead of quitting the app', () async {
    final source = await File('lib/widgets/app_drawer.dart').readAsString();

    expect(source, contains('AuthService'));
    expect(source, contains('signOut()'));
    expect(source, isNot(contains('SystemNavigator.pop')));
  });

  test('navigation, Google login, and admin access flow should be present', () async {
    final navSource = await File('lib/widgets/app_bottom_nav.dart').readAsString();
    final drawerSource = await File('lib/widgets/app_drawer.dart').readAsString();
    final loginSource = await File('lib/screens/login_screen.dart').readAsString();
    final adminSource = await File('lib/screens/admin_screen.dart').readAsString();
    final authSource = await File('lib/services/auth_service.dart').readAsString();

    expect(navSource, contains('pushAndRemoveUntil'));
    expect(navSource, contains('HomeScreen'));
    expect(navSource, contains('Daha Fazla'));
    expect(navSource, contains('Geri Bildirim'));
    expect(navSource, contains('Duyurular'));
    expect(navSource, contains('Bizi Takip Et'));
    expect(loginSource, contains('Google ile Bağlan'));
    expect(authSource, contains('GoogleAuthProvider'));
    expect(adminSource, contains('Konu Başlığı'));
    expect(adminSource, isNot(contains('Ders Adı')));
    expect(drawerSource, isNot(contains('Admin Paneli')));
    expect(loginSource, contains("email.toLowerCase() == 'admin' && password == 'admin'"));
    expect(loginSource, isNot(contains('Admin Girişi')));
  });
}
