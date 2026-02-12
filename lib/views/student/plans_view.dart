import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlansView extends StatelessWidget {
  const PlansView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Welcome to Na9raw E-learning!"),
            ElevatedButton(
              onPressed: () => context.push('/signin'),
              child: const Text('Go to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
