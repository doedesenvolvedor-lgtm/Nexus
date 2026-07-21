import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import '../../widgets/custom_widgets.dart';

// ============================================
// 1. LOGIN SCREEN - Premium Edition
// ============================================

class LoginScreenPremium extends StatefulWidget {
  const LoginScreenPremium({super.key});

  @override
  State<LoginScreenPremium> createState() => _LoginScreenPremiumState();
}

class _LoginScreenPremiumState extends State<LoginScreenPremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email obrigatório';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Senha obrigatória';
    if (text.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await authService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      if (response.success && response.token != null) {
        final authProvider = context.read<AuthProvider>();
        await authProvider.login(
          emailController.text.trim(),
          response.token!,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity:
                    Tween<double>(begin: 0, end: 1).animate(_animationController),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo/Título
                      Center(
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.primaryGradient.createShader(
                                Rect.fromLTWH(
                                  0,
                                  0,
                                  bounds.width,
                                  bounds.height,
                                ),
                              ),
                              child: Text(
                                'N',
                                style: GoogleFonts.poppins(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'NEXUSTWOS',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Título da tela
                      Text(
                        'Bem-vindo de volta',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        'Entre para acessar seu universo de entretenimento',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email Field
                      CustomTextField(
                        label: 'Email',
                        hint: 'seu@email.com',
                        controller: emailController,
                        validator: _validateEmail,
                        prefixIcon: Icons.mail_outline,
                      ),

                      const SizedBox(height: 20),

                      // Password Field
                      CustomTextField(
                        label: 'Senha',
                        hint: '••••••••',
                        controller: passwordController,
                        validator: _validatePassword,
                        isPassword: !_showPassword,
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: _showPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      const SizedBox(height: 16),

                      // "Esqueci minha senha" link
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/forgot-password'),
                          child: Text(
                            'Esqueci minha senha',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryPurple,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Login Button
                      PrimaryButton(
                        label: 'ENTRAR',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        isEnabled: !_isLoading,
                      ),

                      const SizedBox(height: 24),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.cardBackground)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ou',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.cardBackground)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Social Login Buttons
                      _buildSocialLoginButton(
                        label: 'Continuar com Google',
                        icon: '🔍',
                        onTap: () {
                          // TODO: Implementar login Google
                        },
                      ),

                      const SizedBox(height: 12),

                      _buildSocialLoginButton(
                        label: 'Continuar com Apple',
                        icon: '🍎',
                        onTap: () {
                          // TODO: Implementar login Apple
                        },
                      ),

                      const SizedBox(height: 32),

                      // Registro link
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Não tem conta? ",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  child: Text(
                                    'Criar conta',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryPurple,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required String label,
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBackground, width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardBackground.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// 2. REGISTER SCREEN - Premium Edition
// ============================================

class RegisterScreenPremium extends StatefulWidget {
  const RegisterScreenPremium({super.key});

  @override
  State<RegisterScreenPremium> createState() => _RegisterScreenPremiumState();
}

class _RegisterScreenPremiumState extends State<RegisterScreenPremium>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Nome obrigatório';
    if (text.length < 3) return 'Mínimo 3 caracteres';
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email obrigatório';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Senha obrigatória';
    if (text.length < 8) return 'Mínimo 8 caracteres';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) {
      return 'Senhas não coincidem';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aceite os termos para continuar')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await authService.register(
        username: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Conta criada! Você ganhou 3 dias de Premium grátis'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar para Trial Welcome
        Navigator.pushReplacementNamed(context, '/trial-welcome');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Form(
              key: _formKey,
              child: FadeTransition(
                opacity:
                    Tween<double>(begin: 0, end: 1).animate(_animationController),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título
                    Text(
                      'Crie sua conta',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      'Junte-se a milhões de fãs de entretenimento',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Nome Field
                    CustomTextField(
                      label: 'Nome',
                      hint: 'Seu nome',
                      controller: nameController,
                      validator: _validateName,
                      prefixIcon: Icons.person_outline,
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      label: 'Email',
                      hint: 'seu@email.com',
                      controller: emailController,
                      validator: _validateEmail,
                      prefixIcon: Icons.mail_outline,
                    ),

                    const SizedBox(height: 20),

                    // Senha Field
                    CustomTextField(
                      label: 'Senha',
                      hint: '••••••••',
                      controller: passwordController,
                      validator: _validatePassword,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ),

                    const SizedBox(height: 20),

                    // Confirmar Senha Field
                    CustomTextField(
                      label: 'Confirmar Senha',
                      hint: '••••••••',
                      controller: confirmPasswordController,
                      validator: _validateConfirmPassword,
                      isPassword: true,
                      prefixIcon: Icons.lock_outline,
                    ),

                    const SizedBox(height: 24),

                    // Termos e Condições
                    Row(
                      children: [
                        Checkbox(
                          value: _agreeToTerms,
                          onChanged: (value) {
                            setState(() => _agreeToTerms = value ?? false);
                          },
                          fillColor: MaterialStateProperty.resolveWith((states) {
                            if (states.contains(MaterialState.selected)) {
                              return AppColors.primaryPurple;
                            }
                            return Colors.transparent;
                          }),
                          side: const BorderSide(
                            color: AppColors.primaryPurple,
                            width: 2,
                          ),
                        ),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: 'Concordo com os ',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              children: [
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () {
                                      // TODO: Abrir termos
                                    },
                                    child: Text(
                                      'Termos e Condições',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryPurple,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    PrimaryButton(
                      label: 'CRIAR CONTA',
                      onPressed: _handleRegister,
                      isLoading: _isLoading,
                      isEnabled: !_isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Login Link
                    Center(
                      child: RichText(
                        text: TextSpan(
                          text: "Já tem conta? ",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Entrar',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryPurple,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Mensagem trial
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.accentColor.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.card_giftcard,
                            color: AppColors.accentColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '🎁 Ganha 3 dias de Premium ao criar conta!',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accentColor,
                              ),
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
        ),
      ),
    );
  }
}

// ============================================
// 3. FORGOT PASSWORD SCREEN
// ============================================

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Email obrigatório';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) return 'Email inválido';
    return null;
  }

  Future<void> _handleForgotPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // TODO: Implementar forgot password
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link de recuperação enviado para seu email'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Ícone
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mail_outline,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Título
                  Text(
                    'Recuperar Senha',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,

                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Informe o email associado à sua conta para receber um link de recuperação',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,

                    ),
                  ),

                  const SizedBox(height: 40),

                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    hint: 'seu@email.com',
                    controller: emailController,
                    validator: _validateEmail,
                    prefixIcon: Icons.mail_outline,
                  ),

                  const SizedBox(height: 32),

                  // Button
                  PrimaryButton(
                    label: 'ENVIAR LINK',
                    onPressed: _handleForgotPassword,
                    isLoading: _isLoading,
                    isEnabled: !_isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
