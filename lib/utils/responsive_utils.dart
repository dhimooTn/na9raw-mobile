import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  // Device type detection
  static bool isMobile(BuildContext context) => width(context) < 600;
  static bool isTablet(BuildContext context) => width(context) >= 600 && width(context) < 900;
  static bool isDesktop(BuildContext context) => width(context) >= 900;

  // Responsive font sizes
  static double fontSize(BuildContext context, double size) {
    double baseWidth = 375.0; // iPhone SE width as base
    double screenWidth = width(context);
    return size * (screenWidth / baseWidth).clamp(0.8, 1.5);
  }

  // Responsive spacing
  static double spacing(BuildContext context, double size) {
    if (isMobile(context)) return size;
    if (isTablet(context)) return size * 1.2;
    return size * 1.5;
  }

  // Responsive padding
  static EdgeInsets padding(BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    double factor = isMobile(context) ? 1.0 : (isTablet(context) ? 1.2 : 1.5);

    if (all != null) {
      return EdgeInsets.all(all * factor);
    }

    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * factor,
      top: (top ?? vertical ?? 0) * factor,
      right: (right ?? horizontal ?? 0) * factor,
      bottom: (bottom ?? vertical ?? 0) * factor,
    );
  }

  // Responsive border radius
  static double radius(BuildContext context, double size) {
    if (isMobile(context)) return size;
    if (isTablet(context)) return size * 1.1;
    return size * 1.2;
  }

  // Get responsive value based on device type
  static T responsive<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        T? desktop,
      }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  // Responsive grid columns
  static int gridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  // Max content width for large screens
  static double maxContentWidth(BuildContext context) {
    return responsive(
      context,
      mobile: width(context),
      tablet: 800,
      desktop: 1200,
    );
  }
}