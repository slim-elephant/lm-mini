// LM-MINI-PRO-STUB
import 'package:flutter/material.dart';

/// Public-build stub: saved Arena runs are a Pro feature that ships only in
/// the official LM Mini app. Renders an informational placeholder.
class ArenaHistoryScreen extends StatelessWidget {
  const ArenaHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arena history')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Arena history is available in the official LM Mini app.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
