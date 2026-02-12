import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to Na9raw E-learning!"),
            ElevatedButton(
              onPressed: () => context.push('/signin'),
              child: const Text('profile view'),
            ),
          ],
        ),
      ),
    );
  }
}
