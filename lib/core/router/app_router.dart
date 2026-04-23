import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    ),
    // Auth routes (PEP-3)
    GoRoute(
      path: '/login',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Login'))),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Register'))),
    ),
    // App shell (post-auth)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Dashboard'))),
    ),
  ],
);
