import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget que exibe o logo Nexustwos
/// Suporta SVG e PNG
class NexustwosBrandLogo extends StatelessWidget {
  final double size;
  final bool useSvg;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const NexustwosBrandLogo({
    super.key,
    this.size = 100,
    this.useSvg = true,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget logo = useSvg
        ? SvgPicture.asset(
            'assets/app_icons/nexustwos-icon.svg',
            width: size,
            height: size,
            semanticsLabel: semanticLabel ?? 'Nexustwos Logo',
          )
        : Image.asset(
            'assets/app_icons/nexustwos-icon.png',
            width: size,
            height: size,
            semanticLabel: semanticLabel ?? 'Nexustwos Logo',
          );

    if (padding != null) {
      logo = Padding(
        padding: padding!,
        child: logo,
      );
    }

    if (onTap != null) {
      logo = GestureDetector(
        onTap: onTap,
        child: logo,
      );
    }

    return logo;
  }
}

/// Variação com tamanhos predefinidos
class NexustwosBrandLogoSmall extends StatelessWidget {
  final VoidCallback? onTap;

  const NexustwosBrandLogoSmall({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexustwosBrandLogo(
      size: 40,
      onTap: onTap,
    );
  }
}

class NexustwosBrandLogoMedium extends StatelessWidget {
  final VoidCallback? onTap;

  const NexustwosBrandLogoMedium({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexustwosBrandLogo(
      size: 80,
      onTap: onTap,
    );
  }
}

class NexustwosBrandLogoLarge extends StatelessWidget {
  final VoidCallback? onTap;

  const NexustwosBrandLogoLarge({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NexustwosBrandLogo(
      size: 150,
      onTap: onTap,
    );
  }
}
