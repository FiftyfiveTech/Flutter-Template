import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ah_button.dart';
import '../../../../shared/widgets/ah_message_sheet.dart';
import '../../../../shared/widgets/ah_text_field.dart';
import '../controllers/host_payout_controller.dart';

/// Payout details — the host's UPI ID, with a corner shortcut to add bank
/// account details instead. Either one is enough to be paid out.
class HostPayoutPage extends ConsumerStatefulWidget {
  const HostPayoutPage({super.key});

  @override
  ConsumerState<HostPayoutPage> createState() => _HostPayoutPageState();
}

class _HostPayoutPageState extends ConsumerState<HostPayoutPage> {
  final _upiController = TextEditingController();

  @override
  void dispose() {
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(hostPayoutControllerProvider.notifier)
        .saveUpi(_upiController.text);
    if (!mounted) return;
    if (saved) {
      showAhMessageSheet(
        context,
        message: 'UPI ID saved',
        tone: AhMessageTone.success,
      );
      return;
    }
    final submitError = ref.read(hostPayoutControllerProvider).submitError;
    if (submitError != null) {
      showAhMessageSheet(
        context,
        message: submitError,
        tone: AhMessageTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostPayoutControllerProvider);
    final bank = state.account.bank;

    // Prefill once the saved details have loaded.
    ref.listen(hostPayoutControllerProvider.select((s) => s.isLoading), (
      wasLoading,
      isLoading,
    ) {
      if (wasLoading != true || isLoading) return;
      _upiController.text =
          ref.read(hostPayoutControllerProvider).account.upiId ?? '';
    });

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Payout details', style: typography.h3),
      ),
      body: SafeArea(
        child: state.isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: context.colors.actionPrimary,
                ),
              )
            : Column(
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AhTextField(
                            label: 'UPI ID',
                            placeholder: 'name@okhdfcbank',
                            controller: _upiController,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(RegExp(r'\s')),
                            ],
                            helperText:
                                'Payouts are sent to this UPI ID. '
                                'Bank details are optional.',
                            errorText: state.fieldErrors['upiId'],
                            onChanged: (_) => ref
                                .read(hostPayoutControllerProvider.notifier)
                                .clearFieldError('upiId'),
                          ),
                          AppSpacing.spacerSm,
                          Align(
                            alignment: Alignment.centerRight,
                            child: AhButton(
                              label: bank == null
                                  ? 'Add bank account details'
                                  : 'Bank account details',
                              variant: AhButtonVariant.tertiary,
                              onPressed: state.isSaving
                                  ? null
                                  : () => context.push('/host/you/payout/bank'),
                            ),
                          ),
                          if (bank != null) ...[
                            AppSpacing.spacerXs,
                            Text(
                              '${bank.bankName} · ${bank.maskedAccountNumber}'
                              ' · ${bank.ifsc}',
                              textAlign: TextAlign.right,
                              style: typography.caption.copyWith(
                                color: context.colors.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: context.colors.borderDefault),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm + AppSpacing.xs,
                        AppSpacing.gutter,
                        AppSpacing.lg,
                      ),
                      child: AhButton(
                        label: 'Save',
                        fullWidth: true,
                        isLoading: state.isSaving,
                        onPressed: _save,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
