import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/host_onboarding/domain/entities/host_onboarding_step.dart';
import '../../features/host_onboarding/presentation/controllers/host_onboarding_progress_controller.dart';
import '../di/session_providers.dart';
import '../theme/app_colors.dart';

/// The app's actual initial route. Loads the persisted [HostSession] and
/// onboarding progress before deciding where to land, so an app restart
/// resumes the host exactly where they left off instead of always
/// starting at H-00 Landing:
/// - no session -> H-00 Landing (never signed up / signed out)
/// - session but no saved progress -> H-05 Home (a returning host, e.g.
///   signed in via H-L Login, who never went through this device's
///   onboarding wizard)
/// - otherwise -> whichever wizard step (or Home) progress says, except
///   [HostOnboardingStep.documents] resumes at H-02 · Host type instead
///   of H-03 · Documents — the host type choice is re-confirmed on every
///   resume rather than skipped straight back into the documents form.
///   The H-03 draft itself is untouched, so continuing from H-02 lands
///   back on H-03 with everything still filled in.
class HostBootstrapPage extends ConsumerStatefulWidget {
  const HostBootstrapPage({super.key});

  @override
  ConsumerState<HostBootstrapPage> createState() => _HostBootstrapPageState();
}

class _HostBootstrapPageState extends ConsumerState<HostBootstrapPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resume());
  }

  Future<void> _resume() async {
    await ref.read(hostSessionControllerProvider.notifier).hydrate();
    await ref.read(hostOnboardingProgressControllerProvider.notifier).hydrate();
    if (!mounted) return;

    final session = ref.read(hostSessionControllerProvider);
    final HostOnboardingStep? step = ref
        .read(hostOnboardingProgressControllerProvider)
        ?.step;

    final target = switch ((session, step)) {
      (null, _) => '/host/landing',
      (_, null) => '/host/home',
      (_, HostOnboardingStep.hostType) => '/host/signup/host-type',
      (_, HostOnboardingStep.documents) => '/host/signup/host-type',
      (_, HostOnboardingStep.verification) =>
        '/host/signup/host-type/documents/verification',
      (_, HostOnboardingStep.home) => '/host/home',
    };
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
