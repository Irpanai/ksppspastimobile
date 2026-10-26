import 'package:flutter/material.dart';

class PremiumHeader extends StatelessWidget {
  final String title;
  final Widget? bottomWidget;
  final bool? showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;

  const PremiumHeader({
    super.key,
    required this.title,
    this.bottomWidget,
    this.showBackButton,
    this.onBackPressed,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    final shouldShowBack = showBackButton ?? canPop;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Centered Title ALWAYS across the entire screen
                Positioned.fill(
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        final double leftSpace = shouldShowBack ? 52.0 : 0.0;
                        final double rightSpace = (actions != null && actions!.isNotEmpty)
                            ? (actions!.length * 48.0 + 8.0)
                            : 0.0;
                        final double sidePadding = leftSpace > rightSpace ? leftSpace : rightSpace;
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: sidePadding),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 2. Back Button (Left)
                if (shouldShowBack)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                          onPressed: () {
                            if (onBackPressed != null) {
                              onBackPressed!();
                            } else if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                // 3. Actions (Right)
                if (actions != null && actions!.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!.map((action) => Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: action,
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (bottomWidget != null) ...[
            const SizedBox(height: 24),
            bottomWidget!,
          ],
        ],
      ),
    );
  }
}