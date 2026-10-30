import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/host_earnings.dart';
import '../../domain/entities/host_payout_account.dart';
import 'host_payout_providers.dart';

part 'host_earnings_controller.g.dart';

class HostEarningsState {
  const HostEarningsState({
    this.isLoading = false,
    this.earnings,
    this.account = const HostPayoutAccount(),
    this.errorMessage,
  });

  final bool isLoading;
  final HostEarnings? earnings;
  final HostPayoutAccount account;
  final String? errorMessage;

  HostEarningsState copyWith({
    bool? isLoading,
    HostEarnings? earnings,
    HostPayoutAccount? account,
    String? errorMessage,
  }) {
    return HostEarningsState(
      isLoading: isLoading ?? this.isLoading,
      earnings: earnings ?? this.earnings,
      account: account ?? this.account,
      errorMessage: errorMessage,
    );
  }
}

/// Backs the Earnings screen: paid-out total, this month's estimate and the
/// saved payout account (to warn when none is set).
@riverpod
class HostEarningsController extends _$HostEarningsController {
  @override
  HostEarningsState build() {
    Future.microtask(load);
    return const HostEarningsState(isLoading: true);
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true);
    final earningsResult = await ref.read(getHostEarningsUseCaseProvider)();
    final accountResult = await ref.read(getHostPayoutUseCaseProvider)();
    if (!ref.mounted) return;

    final account = accountResult.when(
      ok: (account) => account,
      err: (_) => state.account,
    );
    state = earningsResult.when(
      ok: (earnings) => HostEarningsState(earnings: earnings, account: account),
      err: (failure) => HostEarningsState(
        earnings: state.earnings,
        account: account,
        errorMessage: failure.message,
      ),
    );
  }
}
