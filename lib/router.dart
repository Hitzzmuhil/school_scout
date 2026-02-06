import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/search/search_screen.dart';
import 'features/detail/school_detail_screen.dart';
import 'features/favorites/favorites_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SearchScreen(),
      routes: [
        GoRoute(
          path: 'school/:id',
          name: 'school_detail',
          builder: (context, state) {
             final id = state.pathParameters['id']!;
             return SchoolDetailScreen(schoolId: id);
          },
        ),
        GoRoute(
          path: 'favorites',
          name: 'favorites',
          builder: (context, state) => const FavoritesScreen(),
        ),
      ],
    ),
  ],
);
