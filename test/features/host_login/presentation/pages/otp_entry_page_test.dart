import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:host_mobile_app/core/di/database_providers.dart';
import 'package:host_mobile_app/core/error/result.dart';
import 'package:host_mobile_app/core/theme/app_theme.dart';
import 'package:host_mobile_app/features/host_login/domain/entities/host_login_result.dart';
import 'package:host_mobile_app/features/host_login/domain/repositories/host_login_repository.dart';
import 'package:host_mobile_app/features/host_login/presentation/controllers/host_login_api_providers.dart';
import 'package:host_mobile_app/features/host_login/presentation/pages/otp_entry_page.dart';

import '../../../../support/fakes.dart';

class _FakeHostLoginRepository implements HostLoginRepository {
  _FakeHostLoginRepository();

  Result<void> requestOtpResult = const Ok(null);
  Result<HostLoginResult> verifyOtpResult = const Ok(
    HostLoginResult(
      accessToken: 'fake_token',
      userId: 'host_123',
      accountStatus: 'active',
    ),
  );
  int requestOtpCallCount = 0;

  @override
  Future<Result<void>> requestOtp(String phoneNumber) async {
    requestOtpCallCount++;
    return requestOtpResult;
  }

  @override
  Future<Result<HostLoginResult>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    return verifyOtpResult;
  }
}

void main() {
  Widget buildSubject({
    required _FakeHostLoginRepository repository,
    String phoneNumber = '+919876543210',
  }) {
    return ProviderScope(
      overrides: [
        hostSessionLocalDatasourceProvider.overrideWithValue(
          FakeHostSessionLocalDatasource(),
        ),
        hostLoginRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        home: OtpEntryPage(phoneNumber: phoneNumber),
      ),
    );
  }

  testWidgets(
    'starts with 30-second cooldown on Resend button and counts down',
    (tester) async {
      final repo = _FakeHostLoginRepository();
      await tester.pumpWidget(buildSubject(repository: repo));

      // Initial state has 30s cooldown
      expect(find.text('Resend in 30s'), findsOneWidget);

      // Advance by 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Resend in 25s'), findsOneWidget);

      // Advance by 25 more seconds (total 30s)
      await tester.pump(const Duration(seconds: 25));
      expect(find.text("Didn't get it? Resend"), findsOneWidget);

      // Tapping resend triggers OTP request and restarts cooldown
      await tester.tap(find.text("Didn't get it? Resend"));
      await tester.pump();
      await tester.pump();

      expect(repo.requestOtpCallCount, 1);
      expect(find.text('Resend in 30s'), findsOneWidget);

      // Advance 1 second
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Resend in 29s'), findsOneWidget);

      // Let remaining timer complete to prevent pending timer issues
      await tester.pump(const Duration(seconds: 30));
    },
  );
}
