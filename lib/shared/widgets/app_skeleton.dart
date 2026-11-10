import 'package:flutter/material.dart';

/// Reusable GPU-accelerated shimmer effect wrapper for skeleton loading.
/// Sweeps a smooth linear gradient horizontally across its child widgets.
class AppShimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE2E8F0),
    this.highlightColor = const Color(0xFFF8FAFC),
    this.duration = const Duration(milliseconds: 1400),
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;
  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}

/// Basic placeholder box with configurable width, height, and border radius.
class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  const AppSkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.color,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton for Mutasi / Transaksi Simpanan list item
class AppSkeletonTransactionTile extends StatelessWidget {
  const AppSkeletonTransactionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const AppSkeletonBox(width: 44, height: 44, borderRadius: 14),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(height: 14, width: 140, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeletonBox(height: 10, width: 100, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              AppSkeletonBox(height: 14, width: 75, borderRadius: 4),
              SizedBox(height: 8),
              AppSkeletonBox(height: 9, width: 45, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

/// Full Skeleton list for Mutasi / Transaksi Simpanan
class AppSkeletonTransactionList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const AppSkeletonTransactionList({
    super.key,
    this.count = 5,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        itemBuilder: (context, index) => const AppSkeletonTransactionTile(),
      ),
    );
  }
}

/// Skeleton for Notifikasi item
class AppSkeletonNotificationTile extends StatelessWidget {
  const AppSkeletonNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBox(width: 40, height: 40, borderRadius: 12),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(height: 14, width: 160, borderRadius: 4),
                SizedBox(height: 8),
                AppSkeletonBox(height: 11, width: double.infinity, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeletonBox(height: 11, width: 140, borderRadius: 4),
                SizedBox(height: 10),
                AppSkeletonBox(height: 9, width: 65, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Skeleton list for Notifikasi
class AppSkeletonNotificationList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const AppSkeletonNotificationList({
    super.key,
    this.count = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        itemBuilder: (context, index) => const AppSkeletonNotificationTile(),
      ),
    );
  }
}

/// Skeleton for Promo Screen cards
class AppSkeletonPromoCard extends StatelessWidget {
  const AppSkeletonPromoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBox(height: 160, width: double.infinity, borderRadius: 20),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                AppSkeletonBox(height: 16, width: 220, borderRadius: 4),
                SizedBox(height: 10),
                AppSkeletonBox(height: 12, width: double.infinity, borderRadius: 4),
                SizedBox(height: 6),
                AppSkeletonBox(height: 12, width: 180, borderRadius: 4),
                SizedBox(height: 12),
                AppSkeletonBox(height: 10, width: 110, borderRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full Skeleton list for Promo Screen
class AppSkeletonPromoList extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const AppSkeletonPromoList({
    super.key,
    this.count = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        itemBuilder: (context, index) => const AppSkeletonPromoCard(),
      ),
    );
  }
}

/// Skeleton for Beranda Promo Carousel
class AppSkeletonCarousel extends StatelessWidget {
  const AppSkeletonCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: 160,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: 2,
          itemBuilder: (context, index) {
            return Container(
              width: 300,
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(24),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Skeleton for Sijaka (Deposito Syariah) Bilyet card
class AppSkeletonSijakaCard extends StatelessWidget {
  const AppSkeletonSijakaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppSkeletonBox(height: 16, width: 140, borderRadius: 4),
              AppSkeletonBox(height: 22, width: 75, borderRadius: 8),
            ],
          ),
          const SizedBox(height: 16),
          const AppSkeletonBox(height: 11, width: 100, borderRadius: 4),
          const SizedBox(height: 6),
          const AppSkeletonBox(height: 22, width: 180, borderRadius: 4),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              AppSkeletonBox(height: 12, width: 110, borderRadius: 4),
              AppSkeletonBox(height: 12, width: 90, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

