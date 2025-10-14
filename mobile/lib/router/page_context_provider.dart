// ABOUTME: Derived provider that parses router location into structured context
// ABOUTME: Single source of truth for "what page are we on?"

import 'package:riverpod/riverpod.dart';
import 'package:openvine/router/router_location_provider.dart';
import 'package:openvine/router/route_utils.dart';

/// Provider that exposes the raw page context stream
///
/// For testing, access this directly: `container.read(pageContextStreamProvider)`
final pageContextStreamProvider = Provider<Stream<RouteContext>>((ref) {
  // Watch the router location stream
  final locationStream = ref.watch(routerLocationStreamProvider);

  // Map each location to parsed context
  return locationStream.map((location) => parseRoute(location));
});

/// StreamProvider that derives structured page context from router location
///
/// This is the primary way for widgets to know "what page am I on?"
/// Automatically updates when router location changes.
///
/// Example:
/// ```dart
/// final context = ref.watch(pageContextProvider);
/// context.when(
///   data: (ctx) {
///     if (ctx.type == RouteType.home) {
///       // Show home feed videos
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => ErrorWidget(e),
/// );
/// ```
final pageContextProvider = StreamProvider<RouteContext>((ref) {
  return ref.watch(pageContextStreamProvider);
});
