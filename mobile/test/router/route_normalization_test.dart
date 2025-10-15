// ABOUTME: Tests for route normalization (canonical URLs)
// ABOUTME: Ensures negative indices, encoding, and unknown paths are normalized

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/router/app_router.dart';
import 'package:openvine/router/route_normalization_provider.dart';

void main() {
  Widget shell(ProviderContainer c) => UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: c.read(goRouterProvider)),
      );

  String currentLocation(ProviderContainer c) {
    final router = c.read(goRouterProvider);
    return router.routeInformationProvider.value.uri.toString();
  }

  testWidgets('normalizes negative indices: /home/-3 -> /home/0',
      (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await tester.pumpWidget(shell(c));

    // Activate normalization provider
    c.read(routeNormalizationProvider);

    c.read(goRouterProvider).go('/home/-3');
    await tester.pump(); // Process the navigation
    await tester.pump(); // Process the post-frame callback redirect

    // After normalization, router location should be canonical
    expect(currentLocation(c), '/home/0');

    // Clean up pending timers from HomeFeed provider (it creates a new one each cycle)
    for (var i = 0; i < 2; i++) {
      await tester.binding.delayed(const Duration(minutes: 11));
      await tester.pump();
    }
  });

  testWidgets('normalizes unknown path -> /home/0', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await tester.pumpWidget(shell(c));

    c.read(routeNormalizationProvider);

    c.read(goRouterProvider).go('/wat/xyz');
    await tester.pump(); // Process the navigation
    await tester.pump(); // Process the post-frame callback redirect

    expect(currentLocation(c), '/home/0');

    // Clean up pending timers from HomeFeed provider (it creates a new one each cycle)
    for (var i = 0; i < 2; i++) {
      await tester.binding.delayed(const Duration(minutes: 11));
      await tester.pump();
    }
  });

  testWidgets('encodes hashtag param consistently', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await tester.pumpWidget(shell(c));

    c.read(routeNormalizationProvider);

    c.read(goRouterProvider).go('/hashtag/rust lang/1'); // space in tag
    await tester.pump(); // Process the navigation
    await tester.pump(); // Process the post-frame callback redirect

    // Should be URL-encoded
    expect(currentLocation(c), contains('rust%20lang'));
  });

  testWidgets('normalizes profile with negative index', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await tester.pumpWidget(shell(c));

    c.read(routeNormalizationProvider);

    c.read(goRouterProvider).go('/profile/npubXYZ/-5');
    await tester.pump(); // Process the navigation
    await tester.pump(); // Process the post-frame callback redirect

    expect(currentLocation(c), '/profile/npubXYZ/0');
  });

  testWidgets('preserves valid canonical URLs unchanged', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);

    await tester.pumpWidget(shell(c));

    c.read(routeNormalizationProvider);

    c.read(goRouterProvider).go('/home/5');
    await tester.pump(); // Process the navigation
    await tester.pump(); // Process the post-frame callback redirect

    expect(currentLocation(c), '/home/5');

    // Clean up pending timers from HomeFeed provider (it creates a new one each cycle)
    for (var i = 0; i < 2; i++) {
      await tester.binding.delayed(const Duration(minutes: 11));
      await tester.pump();
    }
  });
}
