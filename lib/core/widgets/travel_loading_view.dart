import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class TravelLoadingView extends StatefulWidget {
  const TravelLoadingView({
    required this.title,
    required this.steps,
    this.icon = Icons.flight_takeoff_rounded,
    super.key,
  });

  final String title;
  final List<String> steps;
  final IconData icon;

  @override
  State<TravelLoadingView> createState() => _TravelLoadingViewState();
}

class _TravelLoadingViewState extends State<TravelLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2, milliseconds: 500),
    )..addListener(_onTick)
      ..forward();
  }

  void _onTick() {
    if (_controller.isCompleted) {
      if (_currentStep < widget.steps.length - 1) {
        setState(() => _currentStep++);
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedIcon(icon: widget.icon),
            const SizedBox(height: 32),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 28),
            ...List.generate(widget.steps.length, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return AnimatedOpacity(
                opacity: isActive || isDone ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 350),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      if (isDone)
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: AppColors.teal,
                        )
                      else if (isActive)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value: _controller.value,
                            color: AppColors.orange,
                            backgroundColor: AppColors.orange.withValues(alpha: .15),
                          ),
                        )
                      else
                        Icon(
                          Icons.circle_outlined,
                          size: 22,
                          color: AppColors.muted.withValues(alpha: .3),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          widget.steps[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w800 : FontWeight.w600,
                            color: isActive
                                ? Theme.of(context).colorScheme.onSurface
                                : isDone
                                    ? AppColors.teal
                                    : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            _ProgressBar(
              progress: (_currentStep + _controller.value) /
                  widget.steps.length,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedIcon extends StatelessWidget {
  const _AnimatedIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.teal, AppColors.navy],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: .3),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 38),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: AppColors.teal.withValues(alpha: .1),
            valueColor: const AlwaysStoppedAnimation(AppColors.teal),
          ),
        ),
      ],
    );
  }
}
