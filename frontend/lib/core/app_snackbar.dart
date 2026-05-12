import 'package:flutter/material.dart';

/// Custom overlay-based notification system for displaying messages at the very top of the screen
class AppSnackBar {
  static const double _borderRadius = 16;
  static const double _horizontalMargin = 16;
  static const double _topMargin = 16;
  static const Duration _defaultDuration = Duration(seconds: 4);
  static const Color _darkBlueBackground = Color(0xFF0B1F4D);

  static OverlayEntry? _currentEntry;

  /// Show a success message with dark blue background
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
    IconData? icon,
  }) {
    _showNotification(
      context,
      message,
      backgroundColor: _darkBlueBackground,
      icon: icon ?? Icons.check_circle,
      duration: duration,
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show an error message with dark blue background
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
    IconData? icon,
  }) {
    _showNotification(
      context,
      message,
      backgroundColor: _darkBlueBackground,
      icon: icon ?? Icons.error,
      duration: duration,
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show a warning message with dark blue background
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
    IconData? icon,
  }) {
    _showNotification(
      context,
      message,
      backgroundColor: _darkBlueBackground,
      icon: icon ?? Icons.warning,
      duration: duration,
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show an info message with dark blue background
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = _defaultDuration,
    IconData? icon,
  }) {
    _showNotification(
      context,
      message,
      backgroundColor: _darkBlueBackground,
      icon: icon ?? Icons.info,
      duration: duration,
      iconColor: Colors.white,
      textColor: Colors.white,
    );
  }

  /// Show a custom notification with specific styling
  static void show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    Duration duration = _defaultDuration,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    _showNotification(
      context,
      message,
      backgroundColor: backgroundColor,
      icon: icon,
      duration: duration,
      textColor: textColor,
      iconColor: iconColor,
    );
  }

  static void _showNotification(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
    required Color textColor,
    required Color iconColor,
  }) {
    // Dismiss keyboard before showing notification
    FocusScope.of(context).unfocus();

    // Remove previous notification if exists
    _currentEntry?.remove();

    // Create animated entry
    _currentEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_horizontalMargin, _topMargin, _horizontalMargin, 0),
            child: _NotificationWidget(
              message: message,
              icon: icon,
              backgroundColor: backgroundColor,
              textColor: textColor,
              iconColor: iconColor,
              duration: duration,
              onDismiss: () {
                _currentEntry?.remove();
                _currentEntry = null;
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentEntry!);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _NotificationWidget extends StatefulWidget {
  const _NotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.iconColor,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    _animationController.reverse().then((_) {
                      widget.onDismiss();
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: widget.textColor,
                    size: 20,
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
