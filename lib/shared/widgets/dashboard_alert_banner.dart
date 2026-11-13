import 'package:flutter/material.dart';

/// Kartu banner aksi seragam untuk Beranda & layar Transaksi agar seluruh
/// notifikasi status (Menunggu Pembayaran, Simpanan Pokok, Tunggakan) memiliki
/// proporsi kartu, ikon, teks, dan tombol kanan yang serasi dan tidak ceking.
class DashboardAlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBgColor;
  final Color accentColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color? buttonColor;
  final VoidCallback onActionTap;
  final VoidCallback? onCardTap;
  final EdgeInsetsGeometry margin;
  final int? maxSubtitleLines;

  const DashboardAlertBanner({
    super.key,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBgColor,
    required this.accentColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.onActionTap,
    this.buttonColor,
    this.onCardTap,
    this.margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.maxSubtitleLines,
  });

  /// Preset amber untuk Menunggu Pembayaran & Perhatian Status Menunggak
  factory DashboardAlertBanner.amber({
    Key? key,
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required VoidCallback onActionTap,
    VoidCallback? onCardTap,
    Color? buttonColor,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    int? maxSubtitleLines,
  }) {
    return DashboardAlertBanner(
      key: key,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      icon: icon,
      backgroundColor: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFDE68A),
      iconBgColor: const Color(0xFFFEF3C7),
      accentColor: const Color(0xFFD97706),
      titleColor: const Color(0xFF92400E),
      subtitleColor: const Color(0xFFB45309),
      buttonColor: buttonColor ?? const Color(0xFFD97706),
      onActionTap: onActionTap,
      onCardTap: onCardTap ?? onActionTap,
      margin: margin,
      maxSubtitleLines: maxSubtitleLines,
    );
  }

  /// Preset hijau emerald untuk kewajiban Simpanan Pokok / info aktif
  factory DashboardAlertBanner.emerald({
    Key? key,
    required String title,
    required String subtitle,
    required String actionLabel,
    required IconData icon,
    required VoidCallback onActionTap,
    VoidCallback? onCardTap,
    Color? buttonColor,
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    int? maxSubtitleLines,
  }) {
    return DashboardAlertBanner(
      key: key,
      title: title,
      subtitle: subtitle,
      actionLabel: actionLabel,
      icon: icon,
      backgroundColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFA7F3D0),
      iconBgColor: const Color(0xFFDCFCE7),
      accentColor: const Color(0xFF047857),
      titleColor: const Color(0xFF065F46),
      subtitleColor: const Color(0xFF047857),
      buttonColor: buttonColor ?? const Color(0xFF047857),
      onActionTap: onActionTap,
      onCardTap: onCardTap ?? onActionTap,
      margin: margin,
      maxSubtitleLines: maxSubtitleLines,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBtnColor = buttonColor ?? accentColor;

    return Padding(
      padding: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap ?? onActionTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: maxSubtitleLines,
                        overflow: maxSubtitleLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
                        softWrap: true,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Material(
                  color: effectiveBtnColor,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onActionTap,
                    borderRadius: BorderRadius.circular(10),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 64, minHeight: 34),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Center(
                          child: Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

