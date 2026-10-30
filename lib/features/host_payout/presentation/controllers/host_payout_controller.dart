import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/host_payout_account.dart';
import '../../domain/usecases/save_host_upi.dart';
import 'host_payout_providers.dart';

part 'host_payout_controller.g.dart';

class HostPayoutState {
  const HostPayoutState({
    this.isLoading = false,
    this.account = const HostPayoutAccount(),
    this.fieldErrors = const {},
    this.isSaving = false,
    this.submitError,
  });

  final bool isLoading;
  final HostPayoutAccount account;
  final Map<String, String> fieldErrors;
  final bool isSaving;

  /// Set when a save fails for a reason not tied to a visible field.
  final String? submitError;

  HostPayoutState copyWith({
    bool? isLoading,
    HostPayoutAccount? account,
    Map<String, String>? fieldErrors,
    bool? isSaving,
    String? submitError,
  }) {
    return HostPayoutState(
      isLoading: isLoading ?? this.isLoading,
      account: account ?? this.account,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      isSaving: isSaving ?? this.isSaving,
      submitError: submitError,
    );
  }
}

/// Shared by the Payout details screen (UPI) and its Bank account details
/// screen — one saved account, two forms.
@riverpod
class HostPayoutController extends _$HostPayoutController {
  @override
  HostPayoutState build() {
    Future.microtask(_load);
    return const HostPayoutState(isLoading: true);
  }

  Future<void> _load() async {
    final result = await ref.read(getHostPayoutUseCaseProvider)();
    if (!ref.mounted) return;
    state = result.when(
      ok: (account) => state.copyWith(isLoading: false, account: account),
      err: (failure) =>
          state.copyWith(isLoading: false, submitError: failure.message),
    );
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    state = state.copyWith(fieldErrors: {...state.fieldErrors}..remove(field));
  }

  /// Returns true once saved; otherwise [HostPayoutState.fieldErrors] or
  /// [HostPayoutState.submitError] is populated.
  Future<bool> saveUpi(String upiId) async {
    state = state.copyWith(isSaving: true, fieldErrors: const {});
    final result = await ref.read(saveHostUpiUseCaseProvider)(upiId);
    if (!ref.mounted) return false;
    return _apply(result);
  }

  Future<bool> saveBank({
    required String holderName,
    required String bankName,
    required String accountNumber,
    required String confirmAccountNumber,
    required String ifsc,
  }) async {
    state = state.copyWith(isSaving: true, fieldErrors: const {});
    final result = await ref.read(saveHostBankUseCaseProvider)(
      holderName: holderName,
      bankName: bankName,
      accountNumber: accountNumber,
      confirmAccountNumber: confirmAccountNumber,
      ifsc: ifsc,
    );
    if (!ref.mounted) return false;
    return _apply(result);
  }

  bool _apply(Result<HostPayoutAccount> result) {
    return result.when(
      ok: (saved) {
        state = state.copyWith(isSaving: false, account: saved);
        return true;
      },
      err: (failure) {
        final fieldErrors = failure is HostPayoutValidationFailure
            ? failure.fieldErrors
            : const <String, String>{};
        state = state.copyWith(
          isSaving: false,
          fieldErrors: fieldErrors,
          submitError: fieldErrors.isEmpty ? failure.message : null,
        );
        return false;
      },
    );
  }
}
