import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Wrap every screen's content in this widget.
/// - scrolls, so nothing overflows on small phones or when the keyboard opens
/// - keeps content at most [maxWidth] wide and centred (tablet / web / desktop)
/// - uses tighter side padding on very narrow phones
class AuthPage extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const AuthPage({super.key, required this.child, this.maxWidth = 480});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final hPad = width < 360 ? 16.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 24),
                child: SizedBox(width: double.infinity, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
