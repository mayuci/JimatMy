import 'package:flutter/material.dart';

import '../widgets/jimatmy_ui.dart';
import '../widgets/mobile_content.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About JimatMY')),
    body: MobileContent(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: JimatMyLogoBadge(size: 76)),
          const SizedBox(height: 16),
          Text(
            'JimatMY',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Compare prices. Save every day.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'JimatMY helps Malaysian consumers compare grocery prices, review price trends and plan shopping within a monthly budget. Price information comes from Malaysia PriceCatcher Open Data.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Version 1.0.0')),
        ],
      ),
    ),
  );
}
