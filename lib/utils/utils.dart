// lib/utils/utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateUtils {
  /// Formato estándar para fechas
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Formato con hora
  static String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  /// Formato para archivos
  static String formatForFile(DateTime date) {
    return DateFormat('yyyyMMdd_HHmmss').format(date);
  }

  /// Formato para API (ISO)
  static String formatForAPI(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

class SnackBarUtils {
  /// Mostrar mensaje de éxito
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Mostrar mensaje de error
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mostrar mensaje informativo
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class DialogUtils {
  /// Mostrar diálogo de confirmación
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? TextButton.styleFrom(foregroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Mostrar loading dialog
  static void showLoading(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message ?? 'Cargando...'),
          ],
        ),
      ),
    );
  }

  /// Cerrar loading dialog
  static void dismissLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
}

class ColorUtils {
  /// Obtener color según tipo de dispositivo
  static Color getDispositivoColor(bool esControlAcceso) {
    return esControlAcceso ? Colors.blue : Colors.green;
  }

  /// Obtener color según estado
  static Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return const Color(0xFF4CAF50);
      case 'baja':
        return const Color(0xFFFF9800);
      case 'perdida':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  /// Obtener color según rol
  static Color getRoleColor(String role) {
    switch (role) {
      case 'root':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }
}

class ValidationUtils {
  /// Validar campo no vacío
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? 'Ingrese $fieldName' : 'Campo requerido';
    }
    return null;
  }

  /// Validar cédula ecuatoriana
  static String? validateCedula(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese la cédula';
    }
    if (value.length != 10) {
      return 'La cédula debe tener 10 dígitos';
    }
    return null;
  }

  /// Validar contraseña
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese la contraseña';
    }
    if (value.length < 6) {
      return 'Mínimo 6 caracteres';
    }
    return null;
  }

  /// Validar ID de tarjeta
  static String? validateCardId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese el ID de la tarjeta';
    }
    if (value.length < 4) {
      return 'ID muy corto';
    }
    return null;
  }
}

class IconUtils {
  /// Obtener icono según tipo
  static IconData getDispositivoIcon(bool esControlAcceso) {
    return esControlAcceso ? Icons.meeting_room : Icons.sensors;
  }

  /// Obtener icono según estado
  static IconData getEstadoIcon(bool autorizado) {
    return autorizado ? Icons.check_circle : Icons.cancel;
  }

  /// Obtener icono según rol
  static IconData getRoleIcon(String role) {
    switch (role) {
      case 'root':
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
