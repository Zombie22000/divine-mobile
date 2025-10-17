// ABOUTME: Tests for VideoEventService replaceable event handling (NIP-33)
// ABOUTME: Verifies that newer versions of replaceable events replace older ones

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:nostr_sdk/nostr_sdk.dart' as sdk;
import 'package:openvine/constants/nip71_migration.dart';
import 'package:openvine/models/video_event.dart';
import 'package:openvine/services/nostr_service_interface.dart';
import 'package:openvine/services/subscription_manager.dart';
import 'package:openvine/services/video_event_service.dart';

@GenerateMocks([INostrService, SubscriptionManager])
import 'video_event_service_replaceable_test.mocks.dart';

void main() {
  group('VideoEventService - Replaceable Events (NIP-33)', () {
    late MockINostrService mockNostrService;
    late MockSubscriptionManager mockSubscriptionManager;
    late VideoEventService service;

    setUp(() {
      mockNostrService = MockINostrService();
      mockSubscriptionManager = MockSubscriptionManager();

      when(mockNostrService.isInitialized).thenReturn(true);

      service = VideoEventService(
        mockNostrService,
        subscriptionManager: mockSubscriptionManager,
      );
    });

    test('newer video event replaces older one with same d-tag', () async {
      // Arrange: Create two versions of the same video (same pubkey + d-tag)
      const pubkey = 'test-pubkey-123';
      const vineId = 'test-vine-abc';
      const videoUrl = 'https://example.com/video.mp4';

      // Old version (timestamp 1000)
      final oldEvent = sdk.Event(
        pubkey,
        NIP71VideoKinds.addressableShortVideo,
        [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'Old Title'],
        ],
        'Old version',
        createdAt: 1000,
      );

      // New version (timestamp 2000) - same pubkey and d-tag
      final newEvent = sdk.Event(
        pubkey,
        NIP71VideoKinds.addressableShortVideo,
        [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'New Title'],
        ],
        'New version',
        createdAt: 2000,
      );

      // Act: Add old event first, then new event
      service.handleEventForTesting(oldEvent, SubscriptionType.discovery);
      service.handleEventForTesting(newEvent, SubscriptionType.discovery);

      // Assert: Should only have the newer event
      final videos = service.discoveryVideos;
      expect(videos.length, 1, reason: 'Should have exactly one video');
      expect(videos[0].id, 'new-event-id', reason: 'Should be the newer event');
      expect(videos[0].title, 'New Title', reason: 'Should have newer title');
    });

    test('older video event is rejected when newer exists', () async {
      // Arrange: Create two versions with reversed timestamps
      const pubkey = 'test-pubkey-456';
      const vineId = 'test-vine-xyz';
      const videoUrl = 'https://example.com/video2.mp4';

      // New version (timestamp 3000)
      final newEvent = sdk.Event(
        id: 'new-event-id-2',
        pubkey: pubkey,
        createdAt: BigInt.from(3000),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'New version',
        tags: [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'Newer Title'],
        ],
        sig: 'new-sig-2',
      );

      // Old version (timestamp 1500)
      final oldEvent = sdk.Event(
        id: 'old-event-id-2',
        pubkey: pubkey,
        createdAt: BigInt.from(1500),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'Old version',
        tags: [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'Older Title'],
        ],
        sig: 'old-sig-2',
      );

      // Act: Add newer event first, then try to add older
      service.handleEventForTesting(newEvent, SubscriptionType.discovery);
      service.handleEventForTesting(oldEvent, SubscriptionType.discovery);

      // Assert: Should still only have the newer event
      final videos = service.discoveryVideos;
      expect(videos.length, 1, reason: 'Should have exactly one video');
      expect(videos[0].id, 'new-event-id-2', reason: 'Should keep the newer event');
      expect(videos[0].title, 'Newer Title', reason: 'Should keep newer title');
    });

    test('different d-tags create separate videos', () async {
      // Arrange: Same pubkey, different d-tags
      const pubkey = 'test-pubkey-789';
      const videoUrl = 'https://example.com/video3.mp4';

      final event1 = sdk.Event(
        id: 'event-1',
        pubkey: pubkey,
        createdAt: BigInt.from(1000),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'Video 1',
        tags: [
          ['d', 'vine-1'],
          ['url', videoUrl],
          ['title', 'Video 1'],
        ],
        sig: 'sig-1',
      );

      final event2 = sdk.Event(
        id: 'event-2',
        pubkey: pubkey,
        createdAt: BigInt.from(2000),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'Video 2',
        tags: [
          ['d', 'vine-2'],
          ['url', videoUrl],
          ['title', 'Video 2'],
        ],
        sig: 'sig-2',
      );

      // Act: Add both events
      service.handleEventForTesting(event1, SubscriptionType.discovery);
      service.handleEventForTesting(event2, SubscriptionType.discovery);

      // Assert: Should have both videos (different d-tags)
      final videos = service.discoveryVideos;
      expect(videos.length, 2, reason: 'Should have two separate videos');
      expect(videos.map((v) => v.id).toSet(), {'event-1', 'event-2'});
    });

    test('different subscription types track replaceable events separately', () async {
      // Arrange: Same video, different subscription types
      const pubkey = 'test-pubkey-999';
      const vineId = 'test-vine-separate';
      const videoUrl = 'https://example.com/video4.mp4';

      final oldEvent = sdk.Event(
        id: 'old-id-separate',
        pubkey: pubkey,
        createdAt: BigInt.from(1000),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'Old',
        tags: [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'Old'],
        ],
        sig: 'sig-old',
      );

      final newEvent = sdk.Event(
        id: 'new-id-separate',
        pubkey: pubkey,
        createdAt: BigInt.from(2000),
        kind: NIP71VideoKinds.addressableShortVideo,
        content: 'New',
        tags: [
          ['d', vineId],
          ['url', videoUrl],
          ['title', 'New'],
        ],
        sig: 'sig-new',
      );

      // Act: Add old to discovery, new to homeFeed
      service.handleEventForTesting(oldEvent, SubscriptionType.discovery);
      service.handleEventForTesting(newEvent, SubscriptionType.homeFeed);

      // Then add new to discovery (should replace old)
      service.handleEventForTesting(newEvent, SubscriptionType.discovery);

      // Assert: Discovery should have new, homeFeed should have new
      final discoveryVideos = service.discoveryVideos;
      final homeFeedVideos = service.homeFeedVideos;

      expect(discoveryVideos.length, 1);
      expect(discoveryVideos[0].id, 'new-id-separate');

      expect(homeFeedVideos.length, 1);
      expect(homeFeedVideos[0].id, 'new-id-separate');
    });

    test('non-replaceable events (kind 22) are not deduplicated', () async {
      // Arrange: Two different kind 22 events (non-addressable)
      const pubkey = 'test-pubkey-222';
      const videoUrl = 'https://example.com/video5.mp4';

      final event1 = sdk.Event(
        id: 'event-kind22-1',
        pubkey: pubkey,
        createdAt: BigInt.from(1000),
        kind: NIP71VideoKinds.shortVideo, // Kind 22 is NOT replaceable
        content: 'Video 1',
        tags: [
          ['url', videoUrl],
          ['title', 'Video 1'],
        ],
        sig: 'sig-22-1',
      );

      final event2 = sdk.Event(
        id: 'event-kind22-2',
        pubkey: pubkey,
        createdAt: BigInt.from(2000),
        kind: NIP71VideoKinds.shortVideo,
        content: 'Video 2',
        tags: [
          ['url', videoUrl],
          ['title', 'Video 2'],
        ],
        sig: 'sig-22-2',
      );

      // Act: Add both events
      service.handleEventForTesting(event1, SubscriptionType.discovery);
      service.handleEventForTesting(event2, SubscriptionType.discovery);

      // Assert: Should have both videos (kind 22 is not replaceable)
      final videos = service.discoveryVideos;
      expect(videos.length, 2, reason: 'Kind 22 events should not replace each other');
    });
  });
}
