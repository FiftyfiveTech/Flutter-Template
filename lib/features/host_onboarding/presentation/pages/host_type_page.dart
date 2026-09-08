import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_card.dart';
import '../../domain/entities/host_type.dart';
import '../controllers/host_type_controller.dart';
import '../widgets/step_progress_dots.dart';

class _HostTypeOption {
  const _HostTypeOption(this.type, this.icon, this.description);

  final HostType type;
  final IconData icon;
  final String description;
}

const _hostTypeOptions = [
  _HostTypeOption(
    HostType.club,
    Icons.nightlife,
    'Recurring parties and pop-ups. Business registration or organiser '
    'ID, PAN, and payout details.',
  ),
  _HostTypeOption(
    HostType.community,
    Icons.groups_outlined,
    'Interest groups and collectives. Same document set as clubs — no '
    'venue paperwork.',
  ),
  _HostTypeOption(
    HostType.venue,
    Icons.storefront_outlined,
    'A licensed premises you operate. Adds address proof, FSSAI and '
    'excise licence on top of the standard set.',
  ),
  _HostTypeOption(
    HostType.individualOperator,
    Icons.person_outline,
    'Hosting solo. Organiser ID, PAN, and payout details only.',
  ),
];

/// H-02 · Host type — decides which documents H-03 asks for.
class HostTypePage extends ConsumerWidget {
  const HostTypePage({super.key});

  void _onContinue(BuildContext context, WidgetRef ref) {
    final result = ref.read(hostTypeControllerProvider.notifier).submit();
    result.when(
      ok: (_) {
        context.push('/host/signup/host-type/documents');
      },
      err: (failure) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final selected = ref.watch(hostTypeControllerProvider);
    final notifier = ref.read(hostTypeControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('What kind of host are you', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.md,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StepProgressDots(currentStep: 2, totalSteps: 4),
                    AppSpacing.spacerMd,
                    Text(
                      "This decides which documents we'll ask for next.",
                      style: typography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppSpacing.spacerLg,
                    for (final option in _hostTypeOptions) ...[
                      AhCard(
                        selected: selected == option.type,
                        onTap: () => notifier.selectHostType(option.type),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              option.icon,
                              size: 22,
                              color: AppColors.actionPrimary,
                            ),
                            AppSpacing.spacerMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.type.label,
                                    style: typography.bodyLg.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppSpacing.spacerXs,
                                  Text(
                                    option.description,
                                    style: typography.bodySm.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.spacerMd,
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm + AppSpacing.xs,
                  AppSpacing.gutter,
                  AppSpacing.lg,
                ),
                child: AhButton(
                  label: 'Continue',
                  fullWidth: true,
                  onPressed: () => _onContinue(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
