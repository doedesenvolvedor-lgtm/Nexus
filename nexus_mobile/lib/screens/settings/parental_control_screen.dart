import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/parental_control_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/parental_control_service.dart';
import '../../theme/colors.dart';

class ParentalControlScreen extends StatefulWidget {
  const ParentalControlScreen({super.key});

  @override
  State<ParentalControlScreen> createState() => _ParentalControlScreenState();
}

class _ParentalControlScreenState extends State<ParentalControlScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _currentPinController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _setupPinMode = false;
  String? _profileId;
  String? _error;

  final _ratings = ['Livre', '10', '12', '14', '16', '18'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    _currentPinController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profileProvider = context.read<ProfileProvider>();
    final profile = profileProvider.selectedProfile;
    if (profile == null) {
      setState(() => _loading = false);
      return;
    }
    _profileId = profile.id;

    final auth = context.read<AuthProvider>();
    final parental = context.read<ParentalControlProvider>();
    parental.setToken(auth.token);

    await parental.loadSettings(profile.id);
    await parental.loadUsage(profile.id);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _handleSave() async {
    final parental = context.read<ParentalControlProvider>();
    final settings = parental.settings;
    if (settings == null || _profileId == null) return;

    setState(() => _saving = true);
    final ok = await parental.updateSettings(_profileId!, settings);
    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Configurações de Controle Parental salvas.'
            : 'Falha ao salvar. Tente novamente.'),
      ),
    );
  }

  Future<void> _setupPin() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmPinController.text.trim();

    if (pin.length < 4 || pin.length > 8) {
      setState(() => _error = 'O PIN deve ter entre 4 e 8 dígitos.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Os PINs não coincidem.');
      return;
    }
    if (_profileId == null) return;

    setState(() {
      _error = null;
      _saving = true;
    });

    final parental = context.read<ParentalControlProvider>();
    final ok = await parental.setPin(_profileId!, pin);
    if (!mounted) return;

    setState(() {
      _saving = false;
      _setupPinMode = false;
    });
    _pinController.clear();
    _confirmPinController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'PIN configurado com sucesso.'
            : 'Falha ao configurar o PIN.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parental = context.watch<ParentalControlProvider>();
    final settings = parental.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Controle Parental')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : settings == null || _profileId == null
              ? const Center(
                  child: Text('Selecione um perfil para configurar o Controle Parental.'),
                )
              : _buildBody(parental, settings),
    );
  }

  Widget _buildBody(
    ParentalControlProvider parental,
    ParentalSettings settings,
  ) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ===== PIN =====
        _sectionCard(
          icon: Icons.pin,
          title: 'PIN de Bloqueio',
          subtitle: settings.hasPin
              ? 'PIN configurado (${settings.maxRating == '18' ? 'proteção ativa' : 'ativo'})'
              : 'Configure um PIN de 4 a 8 dígitos',
          child: _setupPinMode
              ? Column(
                  children: [
                    TextField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Novo PIN (4 a 8 dígitos)',
                        prefixIcon: Icon(Icons.pin),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmPinController,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 8,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Confirmar PIN',
                        prefixIcon: Icon(Icons.pin_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    setState(() {
                                      _setupPinMode = false;
                                      _error = null;
                                    });
                                  },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving ? null : _setupPin,
                            child: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Salvar PIN'),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Text(
                        settings.hasPin
                            ? 'PIN já configurado. ${settings.lockedByPin ? 'Bloqueio exigido para alterações.' : ''}'
                            : 'Nenhum PIN configurado.',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: settings.hasPin ? 'Alterar PIN' : 'Definir PIN',
                      onPressed: () => setState(() {
                        _setupPinMode = true;
                        _error = null;
                      }),
                      icon: Icon(settings.hasPin ? Icons.edit : Icons.add),
                    ),
                  ],
                ),
        ),

        const SizedBox(height: 16),

        // ===== Perfil / Classificação =====
        _sectionCard(
          icon: Icons.verified_user,
          title: 'Classificação Indicativa',
          subtitle: 'Classificação máxima permitida para este perfil',
          child: DropdownButtonFormField<String>(
            initialValue: _normalizeRating(settings.maxRating),
            decoration: const InputDecoration(
              labelText: 'Classificação máxima',
              border: OutlineInputBorder(),
            ),
            items: _ratings
                .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              final updated = ParentalSettings(
                profileId: settings.profileId,
                maxRating: _toBackendRating(value),
                dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                allowedStartTime: settings.allowedStartTime,
                allowedEndTime: settings.allowedEndTime,
                hideAdultContent: settings.hideAdultContent,
                lockedByPin: settings.lockedByPin,
                biometricEnabled: settings.biometricEnabled,
                requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                blockAdultChannels: settings.blockAdultChannels,
                hasPin: settings.hasPin,
              );
              parental.updateSettings(_profileId!, updated);
            },
          ),
        ),

        const SizedBox(height: 16),

        // ===== Conteúdo +18 =====
        _sectionCard(
          icon: Icons.eighteen_up_rating,
          title: 'Conteúdo +18',
          subtitle: 'Controle de conteúdo adulto',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.hideAdultContent,
                title: const Text('Ocultar conteúdo +18 da interface'),
                onChanged: (value) {
                  final updated = ParentalSettings(
                    profileId: settings.profileId,
                    maxRating: settings.maxRating,
                    dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                    allowedStartTime: settings.allowedStartTime,
                    allowedEndTime: settings.allowedEndTime,
                    hideAdultContent: value,
                    lockedByPin: settings.lockedByPin,
                    biometricEnabled: settings.biometricEnabled,
                    requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                    blockAdultChannels: settings.blockAdultChannels,
                    hasPin: settings.hasPin,
                  );
                  parental.updateSettings(_profileId!, updated);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.blockAdultChannels,
                title: const Text('Bloquear canais classificados como adultos'),
                onChanged: (value) {
                  final updated = ParentalSettings(
                    profileId: settings.profileId,
                    maxRating: settings.maxRating,
                    dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                    allowedStartTime: settings.allowedStartTime,
                    allowedEndTime: settings.allowedEndTime,
                    hideAdultContent: settings.hideAdultContent,
                    lockedByPin: settings.lockedByPin,
                    biometricEnabled: settings.biometricEnabled,
                    requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                    blockAdultChannels: value,
                    hasPin: settings.hasPin,
                  );
                  parental.updateSettings(_profileId!, updated);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== Tempo de Uso =====
        _sectionCard(
          icon: Icons.timer,
          title: 'Tempo de Uso Diário',
          subtitle: 'Limite máximo de uso por dia (minutos)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.dailyTimeLimitMinutes == 0
                    ? 'Sem limite de tempo'
                    : 'Máximo: ${settings.dailyTimeLimitMinutes} min/dia',
                style: const TextStyle(fontSize: 14),
              ),
              Slider(
                value: settings.dailyTimeLimitMinutes.toDouble().clamp(0, 720),
                max: 720,
                divisions: 24,
                label: settings.dailyTimeLimitMinutes == 0
                    ? 'Sem limite'
                    : '${settings.dailyTimeLimitMinutes} min',
                onChanged: (value) {
                  final updated = ParentalSettings(
                    profileId: settings.profileId,
                    maxRating: settings.maxRating,
                    dailyTimeLimitMinutes: value.round(),
                    allowedStartTime: settings.allowedStartTime,
                    allowedEndTime: settings.allowedEndTime,
                    hideAdultContent: settings.hideAdultContent,
                    lockedByPin: settings.lockedByPin,
                    biometricEnabled: settings.biometricEnabled,
                    requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                    blockAdultChannels: settings.blockAdultChannels,
                    hasPin: settings.hasPin,
                  );
                  parental.updateSettings(_profileId!, updated);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Uso de hoje: ${parental.usageMinutes} min',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== Horários Permitidos =====
        _sectionCard(
          icon: Icons.schedule,
          title: 'Horários Permitidos',
          subtitle: 'Janela de acesso diário',
          child: Row(
            children: [
              Expanded(
                child: _timeField(
                  label: 'Início',
                  value: settings.allowedStartTime,
                  onChanged: (time) {
                    final updated = ParentalSettings(
                      profileId: settings.profileId,
                      maxRating: settings.maxRating,
                      dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                      allowedStartTime: time,
                      allowedEndTime: settings.allowedEndTime,
                      hideAdultContent: settings.hideAdultContent,
                      lockedByPin: settings.lockedByPin,
                      biometricEnabled: settings.biometricEnabled,
                      requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                      blockAdultChannels: settings.blockAdultChannels,
                      hasPin: settings.hasPin,
                    );
                    parental.updateSettings(_profileId!, updated);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _timeField(
                  label: 'Fim',
                  value: settings.allowedEndTime,
                  onChanged: (time) {
                    final updated = ParentalSettings(
                      profileId: settings.profileId,
                      maxRating: settings.maxRating,
                      dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                      allowedStartTime: settings.allowedStartTime,
                      allowedEndTime: time,
                      hideAdultContent: settings.hideAdultContent,
                      lockedByPin: settings.lockedByPin,
                      biometricEnabled: settings.biometricEnabled,
                      requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                      blockAdultChannels: settings.blockAdultChannels,
                      hasPin: settings.hasPin,
                    );
                    parental.updateSettings(_profileId!, updated);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ===== Segurança =====
        _sectionCard(
          icon: Icons.security,
          title: 'Segurança',
          subtitle: 'Reautenticação e bloqueio',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: settings.biometricEnabled,
                title: const Text('Usar biometria para alterar configurações'),
                onChanged: (value) {
                  final updated = ParentalSettings(
                    profileId: settings.profileId,
                    maxRating: settings.maxRating,
                    dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                    allowedStartTime: settings.allowedStartTime,
                    allowedEndTime: settings.allowedEndTime,
                    hideAdultContent: settings.hideAdultContent,
                    lockedByPin: settings.lockedByPin,
                    biometricEnabled: value,
                    requireAuthAfterMinutes: settings.requireAuthAfterMinutes,
                    blockAdultChannels: settings.blockAdultChannels,
                    hasPin: settings.hasPin,
                  );
                  parental.updateSettings(_profileId!, updated);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.timer_off),
                title: const Text('Reautenticar após inatividade'),
                subtitle: Text(
                  _formatInactivity(settings.requireAuthAfterMinutes),
                ),
                trailing: DropdownButton<int>(
                  value: settings.requireAuthAfterMinutes,
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 min')),
                    DropdownMenuItem(value: 15, child: Text('15 min')),
                    DropdownMenuItem(value: 30, child: Text('30 min')),
                    DropdownMenuItem(value: 60, child: Text('60 min')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    final updated = ParentalSettings(
                      profileId: settings.profileId,
                      maxRating: settings.maxRating,
                      dailyTimeLimitMinutes: settings.dailyTimeLimitMinutes,
                      allowedStartTime: settings.allowedStartTime,
                      allowedEndTime: settings.allowedEndTime,
                      hideAdultContent: settings.hideAdultContent,
                      lockedByPin: settings.lockedByPin,
                      biometricEnabled: settings.biometricEnabled,
                      requireAuthAfterMinutes: value,
                      blockAdultChannels: settings.blockAdultChannels,
                      hasPin: settings.hasPin,
                    );
                    parental.updateSettings(_profileId!, updated);
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ===== Salvar =====
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _saving ? null : _handleSave,
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Salvar Configurações'),
        ),
      ],
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primaryPurple, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required String value,
    required ValueChanged<String> onChanged,
  }) {
    return OutlinedButton(
      onPressed: () async {
        final parts = value.split(':');
        final initial = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          final formatted =
              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onChanged(formatted);
        }
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  String _normalizeRating(String rating) {
    final lower = rating.toLowerCase();
    if (lower == 'livre' || lower == 'l' || lower == 'g') return 'Livre';
    return rating;
  }

  String _toBackendRating(String display) {
    return display == 'Livre' ? 'Livre' : display;
  }

  String _formatInactivity(int minutes) {
    if (minutes <= 0) return 'Sem reautenticação';
    if (minutes < 60) return 'Após $minutes minuto(s)';
    return 'Após ${minutes ~/ 60} hora(s)';
  }
}
