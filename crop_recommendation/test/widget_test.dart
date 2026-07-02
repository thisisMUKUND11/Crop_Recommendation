// Unit tests for HARVEST-IQ.
//
// The previous default "counter" smoke test did not match this app (there is
// no counter, and MyApp requires providers + platform plugins that aren't
// available in the test harness). It is replaced with a focused, plugin-free
// test of ThemeProvider's state transitions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:harvest_iq/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    test('defaults to light mode', () {
      expect(ThemeProvider().themeMode, ThemeMode.light);
    });

    test('toggleTheme switches to dark and back to light', () {
      final provider = ThemeProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      provider.toggleTheme(true);
      expect(provider.themeMode, ThemeMode.dark);

      provider.toggleTheme(false);
      expect(provider.themeMode, ThemeMode.light);

      expect(notifications, 2);
    });
  });
}
