import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final username = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final service = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  String? _validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe seu nome de usuário.';
    }
    if (text.length < 3) {
      return 'Use pelo menos 3 caracteres.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return 'Informe seu e-mail.';
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(text)) {
      return 'E-mail inválido.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Informe uma senha.';
    }
    if (text.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if ((value ?? '') != password.text) {
      return 'As senhas não conferem.';
    }
    return null;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _loading = true);
    final response = await service.register(
      email: email.text.trim(),
      password: password.text,
      username: username.text.trim(),
    );
    if (!mounted) {
      return;
    }

    setState(() => _loading = false);
    messenger.showSnackBar(SnackBar(content: Text(response.message)));

    if (!response.success) {
      return;
    }

    navigator.pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    username.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: username,
                textInputAction: TextInputAction.next,
                validator: _validateUsername,
                decoration: const InputDecoration(labelText: 'Nome de usuário'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: password,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.next,
                validator: _validatePassword,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: confirmPassword,
                obscureText: true,
                autofillHints: const [AutofillHints.newPassword],
                validator: _validateConfirmPassword,
                decoration: const InputDecoration(labelText: 'Confirmar senha'),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cadastrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
