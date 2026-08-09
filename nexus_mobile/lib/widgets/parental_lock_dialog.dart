import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/parental_control_provider.dart';

/// Diálogo reutilizável de desbloqueio do Controle Parental.
///
/// Exibe uma mensagem amigável + campo de PIN. Quando a biometria está
/// habilitada no perfil, oferece um botão de biometria com fallback para PIN
/// (via promessa de API futura — sem dependency local_auth instalada).
class ParentalLockDialog extends StatefulWidget {
  final String profileId;
  final String title;
  final String message;
  final bool showBiometryButton;

  const ParentalLockDialog({
    super.key,
    required this.profileId,
    this.title = 'Conteúdo restrito',
    this.message = 'Conteúdo protegido pelo Controle Parental.\nInforme o PIN para continuar.',
    this.showBiometryButton = true,
  });

  /// Abre o diálogo e retorna `true` se o PIN foi verificado.
  static Future<bool> show(
    BuildContext context, {
    required String profileId,
    String title = 'Conteúdo restrito',
    String message = 'Conteúdo protegido pelo Controle Parental.\nInforme o PIN para continuar.',
    bool showBiometryButton = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ParentalLockDialog(
        profileId: profileId,
        title: title,
        message: message,
        showBiometryButton: showBiometryButton,
      ),
    );
    return result ?? false;
  }

  @override
  State<ParentalLockDialog> createState() => _ParentalLockDialogState();
}

class _ParentalLockDialogState extends State<ParentalLockDialog> {
  final _pinController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Digite o PIN para continuar.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final provider = context.read<ParentalControlProvider>();
    final ok = await provider.unlockWithPin(widget.profileId, pin);

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'PIN incorreto. Tente novamente.');
      HapticFeedback.vibrate();
    }
  }

  Future<void> _biometricUnlock() async {
    // Biometria: como o pacote local_auth não está instalado, tentamos usar
    // o PIN como fallback. Em produção, integrar com local_auth.
    setState(() => _error = 'Biometria não configurada neste dispositivo. Use o PIN.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.lock_outline, color: scheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(widget.title)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, size: 56, color: scheme.primary),
          const SizedBox(height: 16),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'PIN',
              prefixIcon: const Icon(Icons.pin),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        if (widget.showBiometryButton)
          IconButton(
            tooltip: 'Usar biometria',
            onPressed: _submitting ? null : _biometricUnlock,
            icon: const Icon(Icons.fingerprint),
          ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Desbloquear'),
        ),
      ],
    );
  }
}
