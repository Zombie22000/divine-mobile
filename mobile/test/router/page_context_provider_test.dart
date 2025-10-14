// ABOUTME: Tests for derived page context provider
// ABOUTME: Verifies route location is parsed into structured context

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/router/page_context_provider.dart';
import 'package:openvine/router/app_router.dart';
import 'package:openvine/router/route_utils.dart';

void main() {
  group('Page Context Provider', () {
    testWidgets('parses home route from router location', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Build widget tree with router
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
          ),
        ),
      );

      // Access the stream and use StreamQueue
      final stream = container.read(pageContextStreamProvider);
      final queue = StreamQueue(stream);
      addTearDown(() async => queue.cancel());

      // Router starts at /home/0, so context should reflect that
      final context = await queue.next;

      expect(context.type, RouteType.home);
      expect(context.videoIndex, 0);
    });

    testWidgets('updates context when router navigates', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Build widget tree
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
          ),
        ),
      );

      // Access the stream and use StreamQueue
      final stream = container.read(pageContextStreamProvider);
      final queue = StreamQueue(stream);
      addTearDown(() async => queue.cancel());

      // Initial state - home
      final initial = await queue.next;
      expect(initial.type, RouteType.home);
      expect(initial.videoIndex, 0);

      // Navigate to explore
      container.read(goRouterProvider).go('/explore/3');
      await tester.pump();

      // Context should update
      final afterExplore = await queue.next;
      expect(afterExplore.type, RouteType.explore);
      expect(afterExplore.videoIndex, 3);

      // Navigate to profile
      container.read(goRouterProvider).go('/profile/npub1test/7');
      await tester.pump();

      // Context should update again
      final afterProfile = await queue.next;
      expect(afterProfile.type, RouteType.profile);
      expect(afterProfile.npub, 'npub1test');
      expect(afterProfile.videoIndex, 7);
    });

    testWidgets('parses hashtag route correctly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
          ),
        ),
      );

      final stream = container.read(pageContextStreamProvider);
      final queue = StreamQueue(stream);
      addTearDown(() async => queue.cancel());

      // Skip initial /home/0
      await queue.next;

      // Navigate to hashtag
      container.read(goRouterProvider).go('/hashtag/bitcoin/2');
      await tester.pump();

      final context = await queue.next;
      expect(context.type, RouteType.hashtag);
      expect(context.hashtag, 'bitcoin');
      expect(context.videoIndex, 2);
    });

    testWidgets('parses camera route correctly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
          ),
        ),
      );

      final stream = container.read(pageContextStreamProvider);
      final queue = StreamQueue(stream);
      addTearDown(() async => queue.cancel());

      // Skip initial /home/0
      await queue.next;

      // Navigate to camera
      container.read(goRouterProvider).go('/camera');
      await tester.pump();

      final context = await queue.next;
      expect(context.type, RouteType.camera);
      expect(context.videoIndex, isNull);
    });

    testWidgets('parses settings route correctly', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: container.read(goRouterProvider),
          ),
        ),
      );

      final stream = container.read(pageContextStreamProvider);
      final queue = StreamQueue(stream);
      addTearDown(() async => queue.cancel());

      // Skip initial /home/0
      await queue.next;

      // Navigate to settings
      container.read(goRouterProvider).go('/settings');
      await tester.pump();

      final context = await queue.next;
      expect(context.type, RouteType.settings);
      expect(context.videoIndex, isNull);
    });
  });
}
