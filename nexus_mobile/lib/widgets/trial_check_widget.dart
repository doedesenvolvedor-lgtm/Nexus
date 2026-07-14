import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trial_provider.dart';
import '../providers/auth_provider.dart';
import '../services/trial_notification_service.dart';
import 'trial_welcome_screen.dart';

class TrialCheck extends StatefulWidget {
  final Widget child;
  final bool showWelcomeOnFirstTrial;

  const TrialCheck({
    Key? key,
    required this.child,
    this.showWelcomeOnFirstTrial = true,
  }) : super(key: key);

  @override
  State<TrialCheck> createState() => _TrialCheckState();
}

class _TrialCheckState extends State<TrialCheck> {
  bool _firstCheckDone = false;
  bool _showWelcome = false;

  @override
  void initState() {
    super.initState();
    _checkTrialStatus();
  }

  Future<void> _checkTrialStatus() async {
    final authProvider = context.read<AuthProvider>();
    final trialProvider = context.read<TrialProvider>();

    if (authProvider.token != null) {
      try {
        await trialProvider.loadTrialStatus(authProvider.token!);

        if (mounted && trialProvider.isTrialActive && widget.showWelcomeOnFirstTrial) {
          // Agendar notificações do trial
          if (trialProvider.trialEndsAt != null) {
            await TrialNotificationService.scheduleTrialNotifications(
              trialProvider.trialEndsAt!,
            );

            setState(() {
              _showWelcome = true;
            });
          }
        }
      } catch (e) {
        debugPrint('Erro ao verificar trial: $e');
      }
    }

    setState(() {
      _firstCheckDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_firstCheckDone) {
      return Scaffold(
        backgroundColor: Colors.black87,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_showWelcome) {
      return TrialWelcomeScreen();
    }

    return widget.child;
  }
}
