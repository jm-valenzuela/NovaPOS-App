import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/rut_validator.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Precargados con la cuenta demo fija (ver "Cuenta de prueba fija" en el
  // README) — a pedido explícito, para no tener que tipearla cada vez que
  // se prueba la app manualmente.
  final _rutController = TextEditingController(text: '81.814.677-9');
  final _emailController = TextEditingController(text: 'admin@novapos-demo.cl');
  final _passwordController = TextEditingController(text: 'Demo1234!');
  bool _passwordVisible = false;

  @override
  void dispose() {
    _rutController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).login(
          rut: RutValidator.normalizarConGuion(_rutController.text),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.point_of_sale, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'NovaPOS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    key: const Key('loginRut'),
                    controller: _rutController,
                    decoration: const InputDecoration(labelText: 'RUT', hintText: '12.345.678-5'),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) return 'Ingresa tu RUT';
                      if (!RutValidator.esValido(valor)) return 'RUT inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('loginEmail'),
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Correo electrónico'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) return 'Ingresa tu correo';
                      if (!valor.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('loginPassword'),
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _enviar(),
                    validator: (valor) {
                      if (valor == null || valor.isEmpty) return 'Ingresa tu contraseña';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('loginSubmit'),
                    onPressed: authState.cargando ? null : _enviar,
                    child: authState.cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Iniciar sesión'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: authState.cargando ? null : () => context.push('/registro-empresa'),
                    child: const Text('¿No tienes cuenta? Registra tu Empresa'),
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
