import 'package:go_router/go_router.dart';

import '../../features/host_home/presentation/pages/host_home_page.dart';
import '../../features/host_login/presentation/pages/otp_entry_page.dart';
import '../../features/host_login/presentation/pages/phone_entry_page.dart';
import '../../features/host_onboarding/presentation/pages/host_documents_page.dart';
import '../../features/host_onboarding/presentation/pages/host_landing_page.dart';
import '../../features/host_onboarding/presentation/pages/host_signup_page.dart';
import '../../features/host_onboarding/presentation/pages/host_type_page.dart';
import '../../features/host_onboarding/presentation/pages/host_verification_page.dart';

final appRouter = GoRouter(
  initialLocation: '/host/landing',
  routes: [
    GoRoute(
      path: '/host/landing',
      name: 'hostLanding',
      builder: (context, state) => const HostLandingPage(),
    ),
    GoRoute(
      path: '/auth/phone',
      name: 'authPhone',
      builder: (context, state) => const PhoneEntryPage(),
    ),
    GoRoute(
      path: '/auth/phone/otp',
      name: 'authOtp',
      builder: (context, state) =>
          OtpEntryPage(phoneNumber: state.extra! as String),
    ),
    GoRoute(
      path: '/host/signup',
      name: 'hostSignup',
      builder: (context, state) => const HostSignupPage(),
    ),
    GoRoute(
      path: '/host/signup/host-type',
      name: 'hostType',
      builder: (context, state) => const HostTypePage(),
    ),
    GoRoute(
      path: '/host/signup/host-type/documents',
      name: 'hostDocuments',
      builder: (context, state) => const HostDocumentsPage(),
    ),
    GoRoute(
      path: '/host/signup/host-type/documents/verification',
      name: 'hostVerification',
      builder: (context, state) => const HostVerificationPage(),
    ),
    GoRoute(
      path: '/host/home',
      name: 'hostHome',
      builder: (context, state) => const HostHomePage(),
    ),
  ],
);
