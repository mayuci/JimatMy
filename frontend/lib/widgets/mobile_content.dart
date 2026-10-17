import 'package:flutter/material.dart';

/// Centers phone-oriented content on wide web viewports while remaining full
/// width on Android and narrow browser windows.
class MobileContent extends StatelessWidget {
  const MobileContent({required this.child, this.safeArea = false, super.key});

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: child,
        ),
      ),
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}
