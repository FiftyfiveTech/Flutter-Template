import 'package:go_router/go_router.dart';

import '../../features/sample_counter/presentation/pages/counter_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'counter',
      builder: (context, state) => const CounterPage(),
    ),
  ],
);
