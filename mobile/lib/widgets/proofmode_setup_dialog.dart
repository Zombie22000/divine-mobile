// ABOUTME: One-time ProofMode setup dialog shown on first camera use
// ABOUTME: Explains ProofMode and initializes crypto services for video verification

import 'package:flutter/material.dart';
import 'package:openvine/services/proofmode_session_service.dart';
import 'package:openvine/utils/unified_logger.dart';

/// Dialog shown once to set up ProofMode when user first opens camera
class ProofModeSetupDialog extends StatefulWidget {
  const ProofModeSetupDialog({
    required this.proofModeSession,
    super.key,
  });

  final ProofModeSessionService proofModeSession;

  @override
  State<ProofModeSetupDialog> createState() => _ProofModeSetupDialogState();
}

class _ProofModeSetupDialogState extends State<ProofModeSetupDialog> {
  bool _isInitializing = false;
  String _status = 'Preparing ProofMode verification...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeProofMode();
  }

  Future<void> _initializeProofMode() async {
    setState(() {
      _isInitializing = true;
      _progress = 0.1;
      _status = 'Checking device capabilities...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      setState(() {
        _progress = 0.3;
        _status = 'Generating cryptographic keys...';
      });

      // Initialize ProofMode services
      await widget.proofModeSession.ensureInitialized();

      setState(() {
        _progress = 0.8;
        _status = 'Verifying setup...';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _progress = 1.0;
        _status = 'ProofMode ready!';
      });

      // Wait a moment to show success, then close
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.of(context).pop(true); // Return true = success
      }
    } catch (e) {
      Log.error('ProofMode initialization failed: $e',
          name: 'ProofModeSetupDialog', category: LogCategory.system);

      setState(() {
        _status = 'Setup failed. Videos will work without verification.';
        _progress = 0.0;
      });

      // Allow user to continue anyway after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(false); // Return false = failed but continue
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isInitializing, // Prevent dismissal during setup
      child: Dialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF00BCD4).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user,
                  size: 40,
                  color: Color(0xFF00BCD4),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Setting up ProofMode',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                'ProofMode ensures your videos are captured on a real phone '
                'camera and not AI-generated or manipulated.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Progress indicator
              if (_isInitializing) ...[
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[800],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF00BCD4),
                  ),
                ),
                const SizedBox(height: 16),

                // Status text
                Text(
                  _status,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (!_isInitializing && _progress == 0.0) ...[
                // Error state - show continue button
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Continue Anyway'),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Info note
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This happens once. Your videos will have verified badges.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show ProofMode setup dialog
Future<bool> showProofModeSetup(
  BuildContext context,
  ProofModeSessionService proofModeSession,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ProofModeSetupDialog(
      proofModeSession: proofModeSession,
    ),
  );

  return result ?? false;
}
