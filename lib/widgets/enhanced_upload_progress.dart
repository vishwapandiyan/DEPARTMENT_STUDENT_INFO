import 'package:flutter/material.dart';
import '../constants/theme.dart';

class EnhancedUploadProgress extends StatefulWidget {
  final String fileName;
  final double progress;
  final String status;
  final bool isCompleted;
  final bool hasError;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  const EnhancedUploadProgress({
    super.key,
    required this.fileName,
    required this.progress,
    required this.status,
    this.isCompleted = false,
    this.hasError = false,
    this.onRetry,
    this.onCancel,
  });

  @override
  State<EnhancedUploadProgress> createState() => _EnhancedUploadProgressState();
}

class _EnhancedUploadProgressState extends State<EnhancedUploadProgress>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _checkController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _checkAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    ));

    if (widget.isCompleted) {
      _checkController.forward();
    }
    
    if (!widget.hasError && !widget.isCompleted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnhancedUploadProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isCompleted && !oldWidget.isCompleted) {
      _pulseController.stop();
      _checkController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _checkAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isCompleted ? 1.0 : _pulseAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                color: _getBorderColor(),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getShadowColor(),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                _buildIcon(),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fileName,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlueDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Status text
                      Text(
                        widget.status,
                        style: AppTheme.bodyMedium.copyWith(
                          color: _getStatusColor(),
                        ),
                      ),
                      
                      // Progress bar
                      if (!widget.isCompleted && !widget.hasError) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.progress,
                            backgroundColor: AppTheme.lightGray,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.progress * 100).toInt()}%',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action buttons
                if (widget.hasError) ...[
                  IconButton(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    color: AppTheme.errorColor,
                    tooltip: 'Retry',
                  ),
                ] else if (!widget.isCompleted) ...[
                  IconButton(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.cancel),
                    color: AppTheme.mediumGray,
                    tooltip: 'Cancel',
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIcon() {
    if (widget.isCompleted) {
      return AnimatedBuilder(
        animation: _checkAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _checkAnimation.value,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
          );
        },
      );
    } else if (widget.hasError) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.error,
          color: Colors.white,
          size: 20,
        ),
      );
    } else {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
        ),
      );
    }
  }

  Color _getBorderColor() {
    if (widget.hasError) return AppTheme.errorColor;
    if (widget.isCompleted) return AppTheme.successColor;
    return AppTheme.primaryBlue.withOpacity(0.3);
  }

  Color _getShadowColor() {
    if (widget.hasError) return AppTheme.errorColor.withOpacity(0.2);
    if (widget.isCompleted) return AppTheme.successColor.withOpacity(0.2);
    return AppTheme.primaryBlue.withOpacity(0.1);
  }

  Color _getStatusColor() {
    if (widget.hasError) return AppTheme.errorColor;
    if (widget.isCompleted) return AppTheme.successColor;
    return AppTheme.mediumGray;
  }
}

class UploadStatusOverlay extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;

  const UploadStatusOverlay({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: color),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: color,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
