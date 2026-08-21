import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../controllers/counter_controller.dart';

class CounterPage extends ConsumerWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(counterControllerProvider);
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Counter Template'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Count Log:',
                style: typography.headingSm.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.spacerSm,
              state.when(
                data: (record) => Text(
                  '${record.value}',
                  style: typography.headingLg.copyWith(
                    color: AppColors.primary,
                    fontSize: 72,
                  ),
                ),
                loading: () => const CircularProgressIndicator(
                  color: AppColors.primary,
                ),
                error: (error, _) => Text(
                  'Error: ${error is Failure ? error.message : error}',
                  style: typography.bodyMd.copyWith(color: AppColors.danger),
                  textAlign: TextAlign.center,
                ),
              ),
              AppSpacing.spacerLg,
              ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => ref.read(counterControllerProvider.notifier).increment(),
                icon: const Icon(Icons.add),
                label: const Text('Increment Count'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
              AppSpacing.spacerMd,
              Text(
                'Limits: Maximum 100 counts.',
                style: typography.bodySm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
