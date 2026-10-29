import 'dart:ui';
import 'package:flutter/material.dart';

/// Unified modern dialog system for KSPPS PASTI mobile app
/// Ensures all alerts, errors, warnings, and confirmations are
/// centered, beautifully styled, and cohesive.
class AppDialog {
  /// Show centered modern Error Dialog
  static Future<T?> showError<T>(
    BuildContext context, {
    String title = 'Terjadi Kesalahan',
    required String message,
    String buttonText = 'Mengerti',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    // User request: Jangan munculkan pesan error timeout
    if (message.trim().isEmpty || message.toLowerCase().contains('timeout')) {
      return Future.value(null);
    }
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFDC2626),
        iconBgColor: const Color(0xFFFEE2E2),
        iconBorderColor: const Color(0xFFFECACA),
        title: title,
        message: message,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFFDC2626),
        onPrimaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (onConfirm != null) onConfirm();
        },
      ),
    );
  }

  /// Show centered modern Warning Dialog
  static Future<T?> showWarning<T>(
    BuildContext context, {
    String title = 'Perhatian',
    required String message,
    String buttonText = 'Mengerti',
    VoidCallback? onConfirm,
    bool barrierDismissible = true,
  }) {
    if (message.trim().isEmpty || message.toLowerCase().contains('timeout')) {
      return Future.value(null);
    }
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFD97706),
        iconBgColor: const Color(0xFFFEF3C7),
        iconBorderColor: const Color(0xFFFDE68A),
        title: title,
        message: message,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFFD97706),
        onPrimaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (onConfirm != null) onConfirm();
        },
      ),
    );
  }

  /// Show centered modern Success Dialog
  static Future<T?> showSuccess<T>(
    BuildContext context, {
    String title = 'Berhasil!',
    required String message,
    String buttonText = 'Lanjutkan',
    VoidCallback? onConfirm,
    bool barrierDismissible = false,
  }) {
    return _showAnimatedDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: Icons.check_circle_outline_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBgColor: const Color(0xFFDCFCE7),
        iconBorderColor: const Color(0xFFA7F3D0),
        title: title,
        message: message,
        primaryButtonText: buttonText,
        primaryButtonColor: const Color(0xFF16A34A),
        onPrimaryPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          if (onConfirm != null) onConfirm();
        },
      ),
    );
  }

  /// Show centered modern Confirmation Dialog
  /// Returns bool: true if user confirms, false if cancelled.
  static Future<bool> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Ya, Lanjutkan',
    String cancelText = 'Batal',
    bool isDestructive = false,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    Widget? customContent,
    bool barrierDismissible = true,
  }) async {
    final result = await _showAnimatedDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      child: _AppDialogContent(
        icon: icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded),
        iconColor: iconColor ?? (isDestructive ? const Color(0xFFDC2626) : const Color(0xFF388E3C)),
        iconBgColor: iconBgColor ?? (isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7)),
        iconBorderColor: isDestructive ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
        title: title,
        message: message,
        customContent: customContent,
        primaryButtonText: confirmText,
        primaryButtonColor: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF388E3C),
        secondaryButtonText: cancelText,
        onPrimaryPressed: () => Navigator.of(context, rootNavigator: true).pop(true),
        onSecondaryPressed: () => Navigator.of(context, rootNavigator: true).pop(false),
      ),
    );
    return result ?? false;
  }

  /// Internal animated dialog launcher with backdrop blur and scale transition
  static Future<T?> _showAnimatedDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.55),
      transitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, _) {
        final curveValue = Curves.easeOutBack.transform(anim1.value);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 3 * anim1.value,
            sigmaY: 3 * anim1.value,
          ),
          child: Transform.scale(
            scale: (0.85 + (curveValue * 0.15)).clamp(0.0, 1.05),
            child: Opacity(
              opacity: anim1.value.clamp(0.0, 1.0),
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AppDialogContent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color iconBorderColor;
  final String title;
  final String message;
  final Widget? customContent;
  final String primaryButtonText;
  final Color primaryButtonColor;
  final String? secondaryButtonText;
  final VoidCallback onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const _AppDialogContent({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.iconBorderColor,
    required this.title,
    required this.message,
    this.customContent,
    required this.primaryButtonText,
    required this.primaryButtonColor,
    this.secondaryButtonText,
    required this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Centered Icon Badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
              border: Border.all(color: iconBorderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withOpacity(0.15),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 34),
            ),
          ),
          const SizedBox(height: 18),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ),
          ),

          // Custom Content if any
          if (customContent != null) ...[
            const SizedBox(height: 14),
            customContent!,
          ],

          const SizedBox(height: 24),

          // Actions
          if (secondaryButtonText != null)
            Row(
              children: [
                // Secondary / Cancel Button
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      onPressed: onSecondaryPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                        backgroundColor: const Color(0xFFF8FAFC),
                        foregroundColor: const Color(0xFF475569),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        secondaryButtonText!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Primary / Confirm Button
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      onPressed: onPrimaryPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryButtonColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      child: Text(
                        primaryButtonText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            // Single Action Button (Full Width)
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: onPrimaryPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryButtonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  primaryButtonText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}