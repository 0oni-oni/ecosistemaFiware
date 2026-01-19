// lib/utils/validators.dart
class Validators {
  /// Validar campo requerido
  static String? required(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '❌ $fieldName es obligatorio';
    }
    return null;
  }

  /// Validar nombre completo
  static String? nombre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '❌ El nombre es obligatorio';
    }
    if (value.trim().length < 3) {
      return '❌ El nombre debe tener al menos 3 caracteres';
    }
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return '❌ El nombre solo puede contener letras';
    }
    return null;
  }

  /// Validar cédula ecuatoriana (10 dígitos)
  static String? cedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '❌ La cédula es obligatoria';
    }

    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.length != 10) {
      return '❌ La cédula debe tener exactamente 10 dígitos';
    }

    if (!RegExp(r'^[0-9]{10}$').hasMatch(cleaned)) {
      return '❌ La cédula solo puede contener números';
    }

    // Validación del dígito verificador
    final digits = cleaned.split('').map(int.parse).toList();
    final provincia = int.parse(cleaned.substring(0, 2));

    if (provincia < 1 || provincia > 24) {
      return '❌ Código de provincia inválido (01-24)';
    }

    int suma = 0;
    for (int i = 0; i < 9; i++) {
      int digit = digits[i];
      if (i % 2 == 0) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      suma += digit;
    }

    final verificador = suma % 10 == 0 ? 0 : 10 - (suma % 10);
    if (verificador != digits[9]) {
      return '❌ Cédula inválida (dígito verificador incorrecto)';
    }

    return null;
  }

  /// Validar contraseña
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return '❌ La contraseña es obligatoria';
    }
    if (value.length < 6) {
      return '❌ La contraseña debe tener mínimo 6 caracteres';
    }
    if (value.length > 50) {
      return '❌ La contraseña es demasiado larga (máx. 50)';
    }
    return null;
  }

  /// Validar usuario
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '❌ El usuario es obligatorio';
    }
    if (value.length < 3) {
      return '❌ El usuario debe tener al menos 3 caracteres';
    }
    if (value.length > 30) {
      return '❌ El usuario es demasiado largo (máx. 30)';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return '❌ Solo letras, números y guion bajo (_)';
    }
    return null;
  }

  /// Validar ID de tarjeta RFID
  static String? tarjetaId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '❌ El ID de tarjeta es obligatorio';
    }
    if (value.length < 4) {
      return '❌ El ID debe tener al menos 4 caracteres';
    }
    if (value.length > 20) {
      return '❌ El ID es demasiado largo (máx. 20)';
    }
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(value.toUpperCase())) {
      return '❌ El ID solo puede contener letras y números';
    }
    return null;
  }

  /// Validar Device ID
  static String? deviceId(String? value, {bool requiresAcceso = false}) {
    if (value == null || value.trim().isEmpty) {
      return '❌ El Device ID es obligatorio';
    }
    if (value.length < 3) {
      return '❌ El Device ID debe tener al menos 3 caracteres';
    }
    if (requiresAcceso && !value.toLowerCase().startsWith('acceso')) {
      return '❌ Dispositivos de control deben empezar con "acceso"';
    }
    return null;
  }

  /// Validar email (opcional)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '❌ El email es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return '❌ Email inválido (ejemplo: usuario@dominio.com)';
    }
    return null;
  }

  /// Validar número positivo
  static String? positiveNumber(String? value, {String fieldName = 'Valor'}) {
    if (value == null || value.trim().isEmpty) {
      return '❌ $fieldName es obligatorio';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return '❌ Debe ser un número válido';
    }
    if (number <= 0) {
      return '❌ $fieldName debe ser mayor a 0';
    }
    return null;
  }

  /// Validar rango
  static String? range(
    String? value, {
    required int min,
    required int max,
    String fieldName = 'Valor',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '❌ $fieldName es obligatorio';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return '❌ Debe ser un número válido';
    }
    if (number < min || number > max) {
      return '❌ $fieldName debe estar entre $min y $max';
    }
    return null;
  }

  /// Validar longitud
  static String? length(
    String? value, {
    int? min,
    int? max,
    String fieldName = 'Este campo',
  }) {
    if (value == null || value.isEmpty) {
      return '❌ $fieldName es obligatorio';
    }
    if (min != null && value.length < min) {
      return '❌ $fieldName debe tener al menos $min caracteres';
    }
    if (max != null && value.length > max) {
      return '❌ $fieldName no puede tener más de $max caracteres';
    }
    return null;
  }

  /// Combinar validadores
  static String? combine(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) return result;
    }
    return null;
  }
}
