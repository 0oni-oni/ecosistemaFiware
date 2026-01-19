// lib/services/notification_service.dart
import 'package:flutter/material.dart';

/// Tipos de notificación
enum NotificationType { success, error, warning, info }

/// Servicio de notificaciones MEJORADO - Mensajes siempre visibles
class NotificationService {
  /// Mostrar notificación con overlay persistente
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration? duration,
    bool dismissible = true,
  }) {
    final config = _getConfig(type);

    // SnackBar siempre visible con duración extendida
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(config.icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: config.color,
        duration: duration ?? config.defaultDuration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: dismissible
            ? SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  /// Notificación de ÉXITO
  static void success(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.success,
      duration: duration ?? const Duration(seconds: 4),
    );
  }

  /// Notificación de ERROR (más visible y persistente)
  static void error(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.error,
      duration: duration ?? const Duration(seconds: 6), // Más tiempo
    );
  }

  /// Notificación de ADVERTENCIA
  static void warning(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      type: NotificationType.warning,
      duration: duration ?? const Duration(seconds: 5),
    );
  }

  /// Notificación INFORMATIVA
  static void info(BuildContext context, String message, {Duration? duration}) {
    show(
      context,
      message: message,
      type: NotificationType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Diálogo de CONFIRMACIÓN MEJORADO
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    NotificationType type = NotificationType.warning,
  }) async {
    final config = _getConfig(type);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(config.icon, color: config.color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(color: config.color)),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.color,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Diálogo INFORMATIVO (sin confirmación) - ✅ CORREGIDO
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    NotificationType type = NotificationType.info,
  }) async {
    final config = _getConfig(type);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(config.icon, color: config.color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Obtener configuración según tipo
  static _NotificationConfig _getConfig(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return _NotificationConfig(
          color: const Color(0xFF4CAF50),
          icon: Icons.check_circle,
          defaultDuration: const Duration(seconds: 4),
        );
      case NotificationType.error:
        return _NotificationConfig(
          color: const Color(0xFFF44336),
          icon: Icons.error,
          defaultDuration: const Duration(seconds: 6),
        );
      case NotificationType.warning:
        return _NotificationConfig(
          color: const Color(0xFFFF9800),
          icon: Icons.warning,
          defaultDuration: const Duration(seconds: 5),
        );
      case NotificationType.info:
        return _NotificationConfig(
          color: const Color(0xFF2196F3),
          icon: Icons.info,
          defaultDuration: const Duration(seconds: 3),
        );
    }
  }
}

/// Configuración de notificación
class _NotificationConfig {
  final Color color;
  final IconData icon;
  final Duration defaultDuration;

  _NotificationConfig({
    required this.color,
    required this.icon,
    required this.defaultDuration,
  });
}

/// Extensión para contexto (uso más simple)
extension NotificationExtension on BuildContext {
  void showSuccess(String message) =>
      NotificationService.success(this, message);

  void showError(String message) => NotificationService.error(this, message);

  void showWarning(String message) =>
      NotificationService.warning(this, message);

  void showInfo(String message) => NotificationService.info(this, message);

  Future<bool> confirmAction({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
  }) => NotificationService.confirm(
    this,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
  );
}
