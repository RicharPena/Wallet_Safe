import 'package:wallet_safe/models/cuenta.dart';
import 'package:wallet_safe/services/cuenta_service.dart';

class ConfigTabController {
  final CuentaService _cuentaService = CuentaService();

  Future<bool> actualizarCuenta(Cuenta cuenta, String? nuevaContrasena) async {
    return await _cuentaService.editarPerfil(
      cuenta,
      nuevaContrasena: nuevaContrasena,
    );
  }
}
