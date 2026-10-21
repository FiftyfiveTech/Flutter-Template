import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../domain/entities/check_in_result.dart';
import '../controllers/check_in_controller.dart';
import '../widgets/check_in_connection_pill.dart';
import '../widgets/check_in_result_card.dart';

/// HOST-OPS-02 · QR scanner. The camera keeps running between guests;
/// each decision shows as a colour-coded card. Admitted guests clear
/// automatically after [_autoDismissAfter]; anything the host must act on
/// (already used, invalid, unverifiable offline) waits for a tap.
class CheckInScannerPage extends ConsumerStatefulWidget {
  const CheckInScannerPage({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<CheckInScannerPage> createState() => _CheckInScannerPageState();
}

class _CheckInScannerPageState extends ConsumerState<CheckInScannerPage> {
  static const _autoDismissAfter = Duration(milliseconds: 1500);

  final _scanner = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  Timer? _autoDismiss;

  CheckInControllerProvider get _provider =>
      checkInControllerProvider(widget.eventId);

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && value.isNotEmpty) {
        ref.read(_provider.notifier).scan(value);
        return;
      }
    }
  }

  void _onResult(CheckInResult? previous, CheckInResult? next) {
    _autoDismiss?.cancel();
    if (next == null || identical(previous, next)) return;
    if (next.outcome.isAdmitted) {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
      _autoDismiss = Timer(_autoDismissAfter, () {
        if (mounted) ref.read(_provider.notifier).dismissResult();
      });
    } else {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(_provider);
    final notifier = ref.read(_provider.notifier);
    ref.listen<CheckInResult?>(
      _provider.select((s) => s.scanResult),
      _onResult,
    );
    final result = state.scanResult;

    return Scaffold(
      backgroundColor: context.colors.textPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.textPrimary,
        foregroundColor: context.colors.textOnAction,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Scan tickets',
          style: typography.h3.copyWith(color: context.colors.textOnAction),
        ),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: const Icon(Icons.flashlight_on_outlined),
            onPressed: _scanner.toggleTorch,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _scanner,
                    onDetect: _onDetect,
                    errorBuilder: (context, error) => _CameraError(
                      error: error,
                      onSearchByName: () => context.push(
                        '/host/events/${widget.eventId}/check-in/guests',
                      ),
                    ),
                  ),
                  const _ScanFrame(),
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.gutter,
                    right: AppSpacing.gutter,
                    child: Center(child: CheckInConnectionPill(state: state)),
                  ),
                  if (state.isProcessingScan && result == null)
                    Center(
                      child: CircularProgressIndicator(
                        color: context.colors.textOnAction,
                      ),
                    ),
                  if (result != null)
                    Positioned(
                      left: AppSpacing.gutter,
                      right: AppSpacing.gutter,
                      bottom: AppSpacing.md,
                      child: SingleChildScrollView(
                        child: CheckInResultCard(
                          result: result,
                          isBusy: state.isProcessingScan,
                          onDismiss: notifier.dismissResult,
                          onQueueForVerification:
                              notifier.queueCurrentScanForVerification,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _BottomBar(
              state: state,
              onSearchByName: () => context.push(
                '/host/events/${widget.eventId}/check-in/guests',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.7,
          child: AspectRatio(
            aspectRatio: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.colors.textOnAction,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onSearchByName});

  final CheckInState state;
  final VoidCallback onSearchByName;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Container(
      color: context.colors.surfaceCard,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${state.checkedInCount} / ${state.totalCount} in'
              '${state.pendingCount > 0 ? ' · ${state.pendingCount} to sync' : ''}',
              style: typography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: onSearchByName,
            child: const Text("Can't scan? Search by name"),
          ),
        ],
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onSearchByName});

  final MobileScannerException error;
  final VoidCallback onSearchByName;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Camera access is off. Allow camera access for this app in your '
            "phone's settings, then come back.",
      MobileScannerErrorCode.unsupported =>
        "This device doesn't have a camera that can scan tickets.",
      _ => "The camera couldn't start. Close this screen and try again.",
    };

    return ColoredBox(
      color: context.colors.textPrimary,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.no_photography_outlined,
                size: AppSpacing.xxl,
                color: context.colors.textOnAction,
              ),
              AppSpacing.spacerMd,
              Text(
                message,
                textAlign: TextAlign.center,
                style: typography.body.copyWith(
                  color: context.colors.textOnAction,
                ),
              ),
              AppSpacing.spacerLg,
              AhButton(label: 'Search by name', onPressed: onSearchByName),
            ],
          ),
        ),
      ),
    );
  }
}
