import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/features/host_payout/data/datasources/host_payout_datasource.dart';
import 'package:host_mobile_app/features/host_payout/data/repository_impl/host_payout_repository_impl.dart';
import 'package:host_mobile_app/features/host_payout/domain/entities/host_payout_account.dart';
import 'package:host_mobile_app/features/host_payout/domain/usecases/save_host_bank.dart';
import 'package:host_mobile_app/features/host_payout/domain/usecases/save_host_upi.dart';

void main() {
  late HostPayoutRepositoryImpl repository;

  setUp(() {
    repository = HostPayoutRepositoryImpl(InMemoryHostPayoutDatasource());
  });

  Map<String, String> errorsOf(Result<HostPayoutAccount> result) => result.when(
    ok: (_) => fail('expected a validation failure'),
    err: (failure) => (failure as HostPayoutValidationFailure).fieldErrors,
  );

  group('SaveHostUpiUseCase', () {
    test('saves the normalised UPI ID', () async {
      final result = await SaveHostUpiUseCase(repository)(' Name@YBL ');
      final account = result.when(ok: (a) => a, err: (_) => null);
      expect(account?.upiId, 'name@ybl');
    });

    test('rejects an invalid UPI ID', () async {
      final result = await SaveHostUpiUseCase(repository)('nope');
      expect(errorsOf(result), containsPair('upiId', isNotEmpty));
    });
  });

  group('SaveHostBankUseCase', () {
    Future<Result<HostPayoutAccount>> save({
      String holder = 'Rahul Kumar',
      String number = '123456789012',
      String confirm = '123456789012',
      String ifsc = 'hdfc0001234',
    }) => SaveHostBankUseCase(repository)(
      holderName: holder,
      accountNumber: number,
      confirmAccountNumber: confirm,
      ifsc: ifsc,
    );

    test('saves normalised details and masks the account number', () async {
      final bank = (await save()).when(ok: (a) => a.bank, err: (_) => null);
      expect(bank?.ifsc, 'HDFC0001234');
      expect(bank?.maskedAccountNumber, '•••• 9012');
    });

    test('flags every invalid field', () async {
      final errors = errorsOf(
        await save(holder: '', number: '12', confirm: '12', ifsc: 'bad'),
      );
      expect(errors.keys, containsAll(['holderName', 'accountNumber', 'ifsc']));
    });

    test('flags a mismatched confirmation', () async {
      final errors = errorsOf(await save(confirm: '123456789013'));
      expect(errors.keys, ['confirmAccountNumber']);
    });
  });
}
