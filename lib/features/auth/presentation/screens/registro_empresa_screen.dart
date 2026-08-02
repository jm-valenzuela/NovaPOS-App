import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/rut_validator.dart';
import '../../domain/models/registrar_empresa_result.dart';
import '../providers/auth_providers.dart';

class RegistroEmpresaScreen extends ConsumerStatefulWidget {
  const RegistroEmpresaScreen({super.key});

  @override
  ConsumerState<RegistroEmpresaScreen> createState() => _RegistroEmpresaScreenState();
}

class _RegistroEmpresaScreenState extends ConsumerState<RegistroEmpresaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _razonSocialController = TextEditingController();
  final _rutController = TextEditingController();
  final _giroComercialController = TextEditingController();
  final _emailEmpresaController = TextEditingController();
  final _nombreSucursalController = TextEditingController(text: 'Casa Matriz');
  final _nombreAdministradorController = TextEditingController();
  final _emailAdministradorController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmarController = TextEditingController();

  ModalidadEmpresa _modalidad = ModalidadEmpresa.saaS;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rutController.dispose();
    _giroComercialController.dispose();
    _emailEmpresaController.dispose();
    _nombreSucursalController.dispose();
    _nombreAdministradorController.dispose();
    _emailAdministradorController.dispose();
    _passwordController.dispose();
    _passwordConfirmarController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(registroEmpresaControllerProvider.notifier).registrar(
          razonSocial: _razonSocialController.text.trim(),
          rut: RutValidator.normalizarConGuion(_rutController.text),
          giroComercial: _giroComercialController.text.trim(),
          emailEmpresa: _emailEmpresaController.text.trim(),
          modalidadEmpresa: _modalidad,
          nombreSucursalInicial: _nombreSucursalController.text.trim(),
          nombreAdministrador: _nombreAdministradorController.text.trim(),
          emailAdministrador: _emailAdministradorController.text.trim(),
          passwordAdministrador: _passwordController.text,
        );
  }

  String? _requerido(String? valor, String etiqueta) {
    if (valor == null || valor.trim().isEmpty) return 'Ingresa $etiqueta';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(registroEmpresaControllerProvider);

    ref.listen(registroEmpresaControllerProvider, (previo, actual) {
      if (actual.error != null && actual.error != previo?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(actual.error!), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
      if (actual.resultado != null && previo?.resultado == null) {
        _mostrarExitoYVolver(actual.resultado!);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Empresa')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Datos de la Empresa', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('razonSocial'),
                    controller: _razonSocialController,
                    decoration: const InputDecoration(labelText: 'Razón social'),
                    validator: (v) => _requerido(v, 'la razón social'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('rutEmpresa'),
                    controller: _rutController,
                    decoration: const InputDecoration(labelText: 'RUT de la Empresa', hintText: '76.192.083-9'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa el RUT';
                      if (!RutValidator.esValido(v)) return 'RUT inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('giroComercial'),
                    controller: _giroComercialController,
                    decoration: const InputDecoration(labelText: 'Giro comercial'),
                    validator: (v) => _requerido(v, 'el giro comercial'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('emailEmpresa'),
                    controller: _emailEmpresaController,
                    decoration: const InputDecoration(labelText: 'Correo de la Empresa'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa el correo de la Empresa';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ModalidadEmpresa>(
                    key: const Key('modalidad'),
                    value: _modalidad,
                    decoration: const InputDecoration(labelText: 'Modalidad'),
                    items: const [
                      DropdownMenuItem(value: ModalidadEmpresa.saaS, child: Text('SaaS')),
                      DropdownMenuItem(value: ModalidadEmpresa.onPremise, child: Text('OnPremise')),
                    ],
                    onChanged: (valor) => setState(() => _modalidad = valor ?? ModalidadEmpresa.saaS),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('nombreSucursal'),
                    controller: _nombreSucursalController,
                    decoration: const InputDecoration(labelText: 'Nombre de la Sucursal inicial'),
                    validator: (v) => _requerido(v, 'el nombre de la Sucursal'),
                  ),
                  const SizedBox(height: 24),
                  Text('Cuenta del Administrador', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('nombreAdministrador'),
                    controller: _nombreAdministradorController,
                    decoration: const InputDecoration(labelText: 'Tu nombre'),
                    validator: (v) => _requerido(v, 'tu nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('emailAdministrador'),
                    controller: _emailAdministradorController,
                    decoration: const InputDecoration(labelText: 'Tu correo (será tu usuario)'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
                      if (!v.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('password'),
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_passwordVisible ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    obscureText: !_passwordVisible,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingresa una contraseña';
                      if (v.length < 8) return 'Debe tener al menos 8 caracteres';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('passwordConfirmar'),
                    controller: _passwordConfirmarController,
                    decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
                    obscureText: !_passwordVisible,
                    validator: (v) {
                      if (v != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('submitRegistroEmpresa'),
                    onPressed: estado.cargando ? null : _enviar,
                    child: estado.cargando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Registrar Empresa'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _mostrarExitoYVolver(RegistrarEmpresaResult resultado) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Empresa registrada'),
        content: const Text('Tu Empresa quedó creada. Ahora inicia sesión con el correo y la contraseña que registraste.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.pop();
            },
            child: const Text('Ir a Iniciar sesión'),
          ),
        ],
      ),
    );
  }
}
