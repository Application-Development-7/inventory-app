import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonLoader extends StatelessWidget {
  const SkeletonLoader.dashboard({super.key, this.desktop = false})
    : _isProducts = false;

  const SkeletonLoader.products({super.key})
    : desktop = false,
      _isProducts = true;

  final bool desktop;
  final bool _isProducts;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest;
    final highlightColor = colorScheme.surface;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: _isProducts ? _productRows(baseColor) : _dashboardCards(baseColor),
    );
  }

  Widget _dashboardCards(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktopLayout = desktop || constraints.maxWidth >= 800;
        final margin = desktopLayout ? 32.0 : 20.0;
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 580
            ? 2
            : 1;
        final cardWidth = (constraints.maxWidth - 14 * (columns - 1)) / columns;

        return SingleChildScrollView(
          padding: EdgeInsets.all(margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _bar(color, height: 28, width: 240)),
                  const SizedBox(width: 16),
                  _bar(color, height: 42, width: 130, radius: 12),
                ],
              ),
              const SizedBox(height: 12),
              _bar(color, height: 16, width: 320),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(
                  4,
                  (_) => SizedBox(
                    width: cardWidth,
                    child: _card(color, height: 150),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (desktopLayout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _card(color, height: 360)),
                    const SizedBox(width: 18),
                    Expanded(child: _card(color, height: 360)),
                  ],
                )
              else ...[
                _card(color, height: 320),
                const SizedBox(height: 16),
                _card(color, height: 240),
                const SizedBox(height: 16),
                _card(color, height: 240),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _productRows(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: compact ? 620 : constraints.maxWidth,
            child: Column(
              children: [
                _bar(color, height: 48, radius: 0),
                Expanded(
                  child: ListView.separated(
                    itemCount: 7,
                    separatorBuilder: (_, _) => const SizedBox(height: 1),
                    itemBuilder: (_, _) => _productRow(color, compact),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _productRow(Color color, bool compact) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: color,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                _bar(color, height: 40, width: 40, radius: 11),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(color, height: 13, width: 160),
                      const SizedBox(height: 7),
                      _bar(color, height: 10, width: 90),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (!compact) const Expanded(flex: 2, child: SizedBox.shrink()),
          const Expanded(flex: 2, child: SizedBox.shrink()),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _bar(color, height: 24, width: 72, radius: 20),
            ),
          ),
          if (!compact) const Expanded(flex: 2, child: SizedBox.shrink()),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _card(Color color, {required double height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(color, height: 16, width: 150),
          const SizedBox(height: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(color, height: 32, width: 140),
                _bar(color, height: 12, width: 210),
                _bar(color, height: 12, width: 170),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(
    Color color, {
    required double height,
    double? width,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
