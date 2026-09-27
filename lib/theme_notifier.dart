import 'package:flutter/material.dart';

// Uygulama genelinde açık/koyu mod durumunu tutar.
// Drawer'daki anahtar (switch) bunu değiştirir, main.dart bunu dinler.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.light);
