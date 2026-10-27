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

/// Bank account details — holder name, account number (entered twice) and
/// IFSC. The saved account number is never shown or prefilled; only its
/// masked form appears on the Payout details screen.
class HostBankDetailsPage extends ConsumerStatefulWidget {
  const HostBankDetailsPage({super.key});

  @override
  ConsumerState<HostBankDetailsPage> createState() =>
      _HostBankDetailsPageState();
}

class _HostBankDetailsPageState extends ConsumerState<HostBankDetailsPage> {
  static const _maxAccountDigits = 18;
  static const _ifscLength = 11;

  final _holderController = TextEditingController();
  final _accountController = TextEditingController();
  final _confirmController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final bank = ref.read(hostPayoutControllerProvider).account.bank;
    _holderController.text = bank?.holderName ?? '';
    _ifscController.text = bank?.ifsc ?? '';
  }

  @override
  void dispose() {
    _holderController.dispose();
    _accountController.dispose();
    _confirmController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(hostPayoutControllerProvider.notifier)
        .saveBank(
          holderName: _holderController.text,
          accountNumber: _accountController.text,
          confirmAccountNumber: _confirmController.text,
          ifsc: _ifscController.text,
        );
    if (!mounted) return;
    if (saved) {
      context.pop();
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

  void _clear(String field) =>
      ref.read(hostPayoutControllerProvider.notifier).clearFieldError(field);

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final state = ref.watch(hostPayoutControllerProvider);
    final errors = state.fieldErrors;
    final digitsOnly = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(_maxAccountDigits),
    ];

    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Bank account details', style: typography.h3),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                      label: 'Account holder name',
                      placeholder: 'As printed on your bank account',
                      controller: _holderController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[A-Za-z .'\-]"),
                        ),
                        LengthLimitingTextInputFormatter(100),
                      ],
                      errorText: errors['holderName'],
                      onChanged: (_) => _clear('holderName'),
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'Account number',
                      placeholder: '9 to 18 digits',
                      controller: _accountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly,
                      errorText: errors['accountNumber'],
                      onChanged: (_) {
                        _clear('accountNumber');
                        _clear('confirmAccountNumber');
                      },
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'Confirm account number',
                      placeholder: 'Re-enter your account number',
                      controller: _confirmController,
                      keyboardType: TextInputType.number,
                      inputFormatters: digitsOnly,
                      errorText: errors['confirmAccountNumber'],
                      onChanged: (_) => _clear('confirmAccountNumber'),
                    ),
                    AppSpacing.spacerMd,
                    AhTextField(
                      label: 'IFSC code',
                      placeholder: 'e.g. HDFC0001234',
                      controller: _ifscController,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp('[A-Za-z0-9]'),
                        ),
                        LengthLimitingTextInputFormatter(_ifscLength),
                        _UpperCaseFormatter(),
                      ],
                      errorText: errors['ifsc'],
                      onChanged: (_) => _clear('ifsc'),
                    ),
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

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}
