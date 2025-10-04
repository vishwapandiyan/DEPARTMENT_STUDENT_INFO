import 'package:flutter/material.dart';
import '../constants/theme.dart';

class EnhancedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final ButtonType type;
  final ButtonSize size;
  final Color? color;
  final bool fullWidth;

  const EnhancedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.color,
    this.fullWidth = false,
  });

  @override
  State<EnhancedButton> createState() => _EnhancedButtonState();
}

class _EnhancedButtonState extends State<EnhancedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePress() {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
      _controller.forward().then((_) {
        setState(() => _isPressed = false);
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _handlePress(),
            child: Container(
              width: widget.fullWidth ? double.infinity : null,
              height: _getButtonHeight(),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: _getBorder(),
                boxShadow: _getShadow(),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? widget.onPressed : null,
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  child: Container(
                    padding: _getPadding(),
                    child: Row(
                      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: _getIconSize(),
                            height: _getIconSize(),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getTextColor(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: _getIconSize(),
                            color: _getTextColor(),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.text,
                          style: _getTextStyle(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.medium:
        return 44;
      case ButtonSize.large:
        return 52;
    }
  }

  EdgeInsetsGeometry _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 20;
      case ButtonSize.large:
        return 24;
    }
  }

  Color _getBackgroundColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppTheme.lightGray;
    }
    
    switch (widget.type) {
      case ButtonType.primary:
        return widget.color ?? AppTheme.primaryBlue;
      case ButtonType.secondary:
        return widget.color ?? AppTheme.secondaryGold;
      case ButtonType.outline:
        return Colors.transparent;
      case ButtonType.text:
        return Colors.transparent;
    }
  }

  Color _getTextColor() {
    if (widget.onPressed == null || widget.isLoading) {
      return AppTheme.mediumGray;
    }
    
    switch (widget.type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
        return Colors.white;
      case ButtonType.outline:
        return widget.color ?? AppTheme.primaryBlue;
      case ButtonType.text:
        return widget.color ?? AppTheme.primaryBlue;
    }
  }

  Border? _getBorder() {
    if (widget.type == ButtonType.outline) {
      return Border.all(
        color: widget.color ?? AppTheme.primaryBlue,
        width: 1.5,
      );
    }
    return null;
  }

  List<BoxShadow> _getShadow() {
    if (widget.type == ButtonType.text || widget.onPressed == null || widget.isLoading) {
      return [];
    }
    
    return [
      BoxShadow(
        color: (widget.color ?? AppTheme.primaryBlue).withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  TextStyle _getTextStyle() {
    final fontSize = widget.size == ButtonSize.small ? 14.0 : 
                    widget.size == ButtonSize.medium ? 16.0 : 18.0;
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: _getTextColor(),
    );
  }
}

enum ButtonType { primary, secondary, outline, text }
enum ButtonSize { small, medium, large }

class FloatingActionButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isLoading;

  const FloatingActionButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.isLoading = false,
  });

  @override
  State<FloatingActionButton> createState() => _FloatingActionButtonState();
}

class _FloatingActionButtonState extends State<FloatingActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null && !widget.isLoading;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isEnabled 
                    ? (widget.backgroundColor ?? AppTheme.primaryBlue)
                    : AppTheme.lightGray,
                shape: BoxShape.circle,
                boxShadow: isEnabled ? [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AppTheme.primaryBlue).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ] : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isEnabled ? () {
                    _controller.forward().then((_) {
                      _controller.reverse();
                      widget.onPressed?.call();
                    });
                  } : null,
                  borderRadius: BorderRadius.circular(28),
                  child: Center(
                    child: widget.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.foregroundColor ?? Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            widget.icon,
                            color: isEnabled 
                                ? (widget.foregroundColor ?? Colors.white)
                                : AppTheme.mediumGray,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
