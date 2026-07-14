import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/trial_provider.dart';

class TrialBanner extends StatefulWidget {
  final VoidCallback? onTap;

  const TrialBanner({
    Key? key,
    this.onTap,
  }) : super(key: key);

  @override
  State<TrialBanner> createState() => _TrialBannerState();
}

class _TrialBannerState extends State<TrialBanner> {
  Timer? _timer;
  int _daysRemaining = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final trialProvider = context.read<TrialProvider>();
      if (mounted && trialProvider.trialEndsAt != null) {
        final difference =
            trialProvider.trialEndsAt!.difference(DateTime.now());
        setState(() {
          _daysRemaining = difference.inDays;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TrialProvider>(
      builder: (context, trialProvider, _) {
        if (!trialProvider.isTrialActive || _daysRemaining < 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade600,
                  Colors.purple.shade800,
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⭐ Trial Premium',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Restam $_daysRemaining ${_daysRemaining == 1 ? 'dia' : 'dias'}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
