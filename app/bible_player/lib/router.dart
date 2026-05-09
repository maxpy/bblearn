import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'screens/player_screen.dart';
import 'services/prefs_service.dart';

final appRouter = GoRouter(
  initialLocation: '/player/${PrefsService.instance.loadLastBook()}/${PrefsService.instance.loadLastChapter()}',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/book/:bookNumber',
      builder: (context, state) {
        final bookNumber = int.parse(state.pathParameters['bookNumber']!);
        return BookScreen(bookNumber: bookNumber);
      },
    ),
    GoRoute(
      path: '/player/:bookNumber/:chapter',
      builder: (context, state) {
        final bookNumber = int.parse(state.pathParameters['bookNumber']!);
        final chapter = int.parse(state.pathParameters['chapter']!);
        return PlayerScreen(bookNumber: bookNumber, chapter: chapter);
      },
    ),
  ],
);
