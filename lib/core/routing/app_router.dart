import 'package:go_router/go_router.dart';

import '../../features/host_events/presentation/pages/host_event_form_page.dart';
import '../../features/host_home/presentation/pages/host_home_page.dart';
import '../../features/host_login/presentation/pages/otp_entry_page.dart';
import '../../features/host_login/presentation/pages/phone_entry_page.dart';
import '../../features/host_onboarding/presentation/pages/host_documents_page.dart';
import '../../features/host_onboarding/presentation/pages/host_landing_page.dart';
import '../../features/host_onboarding/presentation/pages/host_signup_page.dart';
import '../../features/host_onboarding/presentation/pages/host_type_page.dart';
import '../../features/host_onboarding/presentation/pages/host_verification_page.dart';
import '../../features/host_profile/presentation/pages/host_you_page.dart';
import '../../features/host_venues/presentation/pages/host_venue_details_page.dart';
import '../../features/host_venues/presentation/pages/host_venues_page.dart';
import 'host_bootstrap_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'hostBootstrap',
      builder: (context, state) => const HostBootstrapPage(),
    ),
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
    GoRoute(
      path: '/host/events/new',
      name: 'hostEventNew',
      builder: (context, state) => const HostEventFormPage(),
    ),
    GoRoute(
      path: '/host/events/:id',
      name: 'hostEventDetails',
      builder: (context, state) =>
          HostEventFormPage(eventId: state.pathParameters['id']),
    ),
    GoRoute(
      path: '/host/you',
      name: 'hostYou',
      builder: (context, state) => const HostYouPage(),
    ),
    GoRoute(
      path: '/host/venues',
      name: 'hostVenues',
      builder: (context, state) => const HostVenuesPage(),
    ),
    GoRoute(
      path: '/host/venues/add',
      name: 'hostVenueAdd',
      builder: (context, state) => const HostVenueDetailsPage(),
    ),
    GoRoute(
      path: '/host/venues/:id',
      name: 'hostVenueDetails',
      builder: (context, state) =>
          HostVenueDetailsPage(venueId: state.pathParameters['id']),
    ),
  ],
);
