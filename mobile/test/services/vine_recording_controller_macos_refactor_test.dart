// ABOUTME: Tests for refactored macOS recording helper methods in VineRecordingController
// ABOUTME: Verifies _getMacOSRecordingPath() and _applyAspectRatioCrop() through finishRecording()

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openvine/models/aspect_ratio.dart';
import 'package:openvine/services/vine_recording_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VineRecordingController macOS Refactored Helper Methods', () {
    late List<MethodCall> methodCalls;
    String? recordingPath;

    setUp(() {
      methodCalls = [];
      recordingPath = null;

      // Set up method channel mock for native macOS camera
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('openvine/native_camera'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'startPreview':
              return true;
            case 'stopPreview':
              return true;
            case 'startRecording':
              // Create a test recording file
              final testDir = Directory.systemTemp.createTempSync('vine_test_');
              final testFile = File('${testDir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.mov');

              // Write minimal valid MP4 header
              final validMp4Bytes = [
                0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70,
                0x69, 0x73, 0x6f, 0x6d, 0x00, 0x00, 0x02, 0x00,
                0x69, 0x73, 0x6f, 0x6d, 0x69, 0x73, 0x6f, 0x32,
                0x61, 0x76, 0x63, 0x31, 0x6d, 0x70, 0x34, 0x31,
              ];
              testFile.writeAsBytesSync(validMp4Bytes);

              recordingPath = testFile.path;
              return true;
            case 'stopRecording':
              return recordingPath;
            case 'hasPermission':
              return true;
            case 'requestPermission':
              return true;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('openvine/native_camera'),
        null,
      );

      // Cleanup test files
      if (recordingPath != null) {
        final file = File(recordingPath!);
        if (file.existsSync()) {
          file.parent.deleteSync(recursive: true);
        }
      }
    });

    testWidgets('should apply square aspect ratio crop via _applyAspectRatioCrop()',
        (tester) async {
      // Skip on non-macOS platforms
      if (kIsWeb || !Platform.isMacOS) {
        return;
      }

      final controller = VineRecordingController();

      try {
        // Set aspect ratio to square BEFORE initialization
        controller.setAspectRatio(AspectRatio.square);

        await controller.initialize();

        // Start recording
        await controller.startRecording();
        expect(controller.state, equals(VineRecordingState.recording));

        // Stop recording immediately (mock returns synchronously)
        await controller.stopRecording();

        // Finish recording - this calls _getMacOSRecordingPath() and _applyAspectRatioCrop()
        final result = await controller.finishRecording();

        // Verify that a cropped file was created
        expect(result.$1, isNotNull, reason: 'Should return a cropped video file');
        expect(result.$1!.existsSync(), isTrue, reason: 'Cropped file should exist');
        expect(result.$1!.path, contains('vine_final_'), reason: 'Should create final cropped file');
        expect(controller.state, equals(VineRecordingState.completed));

        // Cleanup cropped file
        if (result.$1!.existsSync()) {
          result.$1!.deleteSync();
        }
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should apply vertical aspect ratio crop via _applyAspectRatioCrop()',
        (tester) async {
      // Skip on non-macOS platforms
      if (kIsWeb || !Platform.isMacOS) {
        return;
      }

      final controller = VineRecordingController();

      try {
        // Set aspect ratio to vertical BEFORE initialization
        controller.setAspectRatio(AspectRatio.vertical);

        await controller.initialize();

        // Start recording
        await controller.startRecording();

        // Wait briefly for recording to establish
        await Future.delayed(const Duration(milliseconds: 100));

        // Stop recording
        await controller.stopRecording();

        // Finish recording - tests _applyAspectRatioCrop() with vertical aspect ratio
        final result = await controller.finishRecording();

        // Verify vertical crop was applied
        expect(result.$1, isNotNull);
        expect(result.$1!.existsSync(), isTrue);
        expect(result.$1!.path, contains('vine_final_'));

        // Cleanup
        if (result.$1!.existsSync()) {
          result.$1!.deleteSync();
        }
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should find recording path via _getMacOSRecordingPath() from stopRecording',
        (tester) async {
      // Skip on non-macOS platforms
      if (kIsWeb || !Platform.isMacOS) {
        return;
      }

      final controller = VineRecordingController();

      try {
        controller.setAspectRatio(AspectRatio.square);
        await controller.initialize();

        await controller.startRecording();
        await Future.delayed(const Duration(milliseconds: 100));
        await controller.stopRecording();

        // At this point, _getMacOSRecordingPath() should be able to find the recording
        // when finishRecording() is called
        final result = await controller.finishRecording();

        // Verify path was found and used
        expect(result.$1, isNotNull,
            reason: '_getMacOSRecordingPath() should find the recording file');

        // The path should be different from the original recording path
        // because _applyAspectRatioCrop() creates a new cropped file
        expect(result.$1!.path, isNot(equals(recordingPath)),
            reason: 'Should return cropped file, not original recording');

        // Cleanup
        if (result.$1!.existsSync()) {
          result.$1!.deleteSync();
        }
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should handle recording completion and apply crop in single flow',
        (tester) async {
      // Skip on non-macOS platforms
      if (kIsWeb || !Platform.isMacOS) {
        return;
      }

      final controller = VineRecordingController();

      try {
        controller.setAspectRatio(AspectRatio.square);
        await controller.initialize();

        // Full recording cycle
        await controller.startRecording();
        await Future.delayed(const Duration(milliseconds: 100));
        await controller.stopRecording();

        // This exercises the full refactored code path:
        // 1. _getMacOSRecordingPath() finds the recording
        // 2. _applyAspectRatioCrop() applies FFmpeg crop
        final result = await controller.finishRecording();

        // Verify end-to-end flow worked
        expect(result.$1, isNotNull);
        expect(result.$1!.existsSync(), isTrue);
        expect(controller.state, equals(VineRecordingState.completed));

        // Verify it's a new cropped file
        expect(result.$1!.path, contains('vine_final_'));
        expect(result.$1!.path, isNot(equals(recordingPath)));

        // Cleanup
        if (result.$1!.existsSync()) {
          result.$1!.deleteSync();
        }
      } finally {
        controller.dispose();
      }
    });

    testWidgets('should handle error when recording path not found',
        (tester) async {
      // Skip on non-macOS platforms
      if (kIsWeb || !Platform.isMacOS) {
        return;
      }

      // Set up mock to return null (no recording)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('openvine/native_camera'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'startPreview':
              return true;
            case 'stopRecording':
              return null; // Simulate missing recording
            case 'hasPermission':
              return true;
            case 'requestPermission':
              return true;
            default:
              return null;
          }
        },
      );

      final controller = VineRecordingController();

      try {
        controller.setAspectRatio(AspectRatio.square);
        await controller.initialize();

        // Try to finish without a valid recording
        // This should trigger an error in _getMacOSRecordingPath()
        expect(
          () => controller.finishRecording(),
          throwsA(isA<Exception>()),
          reason: '_getMacOSRecordingPath() should throw when no recording found',
        );
      } finally {
        controller.dispose();
      }
    });
  });
}
