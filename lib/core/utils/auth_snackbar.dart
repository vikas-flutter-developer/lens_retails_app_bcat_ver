import 'package:flutter/material.dart';

enum AuthSnackBarType { success, error, info }

class AuthSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    required AuthSnackBarType type,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    final themeColor = _getColor(type);
    final icon = _getIcon(type);
    final defaultTitle = _getDefaultTitle(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        content: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B), // Sleek, modern dark slate background
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Soft accent glow on the left
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    color: themeColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      // Circular Icon background
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Message Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title ?? defaultTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8), // Soft slate text
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: Color(0xFF64748B),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Color _getColor(AuthSnackBarType type) {
    switch (type) {
      case AuthSnackBarType.success:
        return const Color(0xFF10B981); // Emerald Green
      case AuthSnackBarType.error:
        return const Color(0xFFEF4444); // Soft Red/Rose
      case AuthSnackBarType.info:
        return const Color(0xFF3B82F6); // Elegant Blue
    }
  }

  static IconData _getIcon(AuthSnackBarType type) {
    switch (type) {
      case AuthSnackBarType.success:
        return Icons.check_circle_rounded;
      case AuthSnackBarType.error:
        return Icons.error_outline_rounded;
      case AuthSnackBarType.info:
        return Icons.info_outline_rounded;
    }
  }

  static String _getDefaultTitle(AuthSnackBarType type) {
    switch (type) {
      case AuthSnackBarType.success:
        return 'Success';
      case AuthSnackBarType.error:
        return 'Oops!';
      case AuthSnackBarType.info:
        return 'Note';
    }
  }
}
