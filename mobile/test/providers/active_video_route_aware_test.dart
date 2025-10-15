// ABOUTME: Tests for route-aware activeVideoIdProvider
// ABOUTME: Verifies active video switches by route type (home/profile/hashtag/explore)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/providers/active_video_provider.dart';
import 'package:openvine/providers/app_lifecycle_provider.dart';
import 'package:openvine/providers/hashtag_feed_providers.dart';
import 'package:openvine/providers/profile_feed_providers.dart';
import 'package:openvine/providers/route_feed_providers.dart';
import 'package:openvine/router/page_context_provider.dart';
import 'package:openvine/router/route_utils.dart';
import 'package:openvine/state/video_feed_state.dart';

void main() {
  final now = DateTime.now();
  final nowUnix = now.millisecondsSinceEpoch ~/ 1000;

  // Helper to create mock video events
  VideoEvent mockVideo(String id) => VideoEvent(
        id: id,
        pubkey: 'pubkey-$id',
        createdAt: nowUnix,
        content: 'Video $id',
        timestamp: now,
        videoUrl: 'https://example.com/$id.mp4',
        thumbnailUrl: 'https://example.com/$id-thumb.jpg',
        duration: 6,
        dimensions: '1080x1920',
      );

  test('activeVideoIdProvider switches by route type - HOME', () {
    final c = ProviderContainer(overrides: [
      appForegroundProvider.overrideWithValue(const AsyncValue.data(true)),
      pageContextProvider.overrideWithValue(
        const AsyncValue.data(RouteContext(type: RouteType.home, videoIndex: 1)),
      ),
      videosForHomeRouteProvider.overrideWith((ref) {
        return AsyncValue.data(VideoFeedState(
          videos: [mockVideo('h0'), mockVideo('h1'), mockVideo('h2')],
          hasMoreContent: false,
          isLoadingMore: false,
        ));
      }),
    ]);
    addTearDown(c.dispose);

    expect(c.read(activeVideoIdProvider), 'h1');
  });

  test('activeVideoIdProvider switches by route type - PROFILE', () {
    final c = ProviderContainer(overrides: [
      appForegroundProvider.overrideWithValue(const AsyncValue.data(true)),
      pageContextProvider.overrideWithValue(
        const AsyncValue.data(
          RouteContext(type: RouteType.profile, npub: 'npubXYZ', videoIndex: 0),
        ),
      ),
      videosForProfileRouteProvider.overrideWith((ref) {
        return AsyncValue.data(VideoFeedState(
          videos: [mockVideo('p0'), mockVideo('p1')],
          hasMoreContent: false,
          isLoadingMore: false,
        ));
      }),
    ]);
    addTearDown(c.dispose);

    expect(c.read(activeVideoIdProvider), 'p0');
  });

  test('activeVideoIdProvider switches by route type - HASHTAG', () {
    final c = ProviderContainer(overrides: [
      appForegroundProvider.overrideWithValue(const AsyncValue.data(true)),
      pageContextProvider.overrideWithValue(
        const AsyncValue.data(
          RouteContext(type: RouteType.hashtag, hashtag: 'rust', videoIndex: 1),
        ),
      ),
      videosForHashtagRouteProvider.overrideWith((ref) {
        return AsyncValue.data(VideoFeedState(
          videos: [mockVideo('t0'), mockVideo('t1'), mockVideo('t2')],
          hasMoreContent: false,
          isLoadingMore: false,
        ));
      }),
    ]);
    addTearDown(c.dispose);

    expect(c.read(activeVideoIdProvider), 't1');
  });

  test('activeVideoIdProvider returns null for unsupported route types', () {
    final c = ProviderContainer(overrides: [
      appForegroundProvider.overrideWithValue(const AsyncValue.data(true)),
      pageContextProvider.overrideWithValue(
        const AsyncValue.data(RouteContext(type: RouteType.camera)),
      ),
    ]);
    addTearDown(c.dispose);

    expect(c.read(activeVideoIdProvider), isNull);
  });

  test('activeVideoIdProvider clamps index above feed length', () {
    final c = ProviderContainer(overrides: [
      appForegroundProvider.overrideWithValue(const AsyncValue.data(true)),
      pageContextProvider.overrideWithValue(
        const AsyncValue.data(RouteContext(type: RouteType.home, videoIndex: 999)),
      ),
      videosForHomeRouteProvider.overrideWith((ref) {
        return AsyncValue.data(VideoFeedState(
          videos: [mockVideo('h0'), mockVideo('h1')],
          hasMoreContent: false,
          isLoadingMore: false,
        ));
      }),
    ]);
    addTearDown(c.dispose);

    // Should clamp to last valid index (1)
    expect(c.read(activeVideoIdProvider), 'h1');
  });
}
