import 'package:go_router/go_router.dart';

import '../../features/host_onboarding/presentation/pages/host_landing_page.dart';

final appRouter = GoRouter(
  initialLocation: '/host/landing',
  routes: [
    GoRoute(
      path: '/host/landing',
      name: 'hostLanding',
      builder: (context, state) => const HostLandingPage(),
    ),
  ],
);
