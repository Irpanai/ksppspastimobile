import 'package:flutter/material.dart';

class PremiumHeader extends StatelessWidget {
  final String title;
  final Widget? bottomWidget;
  final bool showBackButton;
  final List<Widget>? actions;

  const PremiumHeader({
    Key? key,
    required this.title,
    this.bottomWidget,
    this.showBackButton = true,
    this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: showBackButton ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (showBackButton)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
                const SizedBox(width: 48), // Balance spacing for center alignment
              if (actions != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!.map((action) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: action,
                    ),
                  )).toList(),
                ),
            ],
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
