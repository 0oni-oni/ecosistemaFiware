# Ecosistema FIWARE

Una aplicación móvil Flutter para el ecosistema FIWARE.

## Descripción

Esta es una aplicación Flutter diseñada para interactuar con el ecosistema FIWARE, una plataforma de código abierto para el desarrollo de soluciones inteligentes.

## Requisitos Previos

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / Xcode (para desarrollo móvil)
- Un editor de código (VS Code, Android Studio, etc.)

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/0oni-oni/ecosistemaFiware.git
cd ecosistemaFiware
```

2. Instalar dependencias:
```bash
flutter pub get
```

3. Ejecutar la aplicación:
```bash
flutter run
```

## Estructura del Proyecto

```
ecosistema_fiware/
├── lib/
│   └── main.dart          # Punto de entrada de la aplicación
├── test/
│   └── widget_test.dart   # Pruebas de widgets
├── android/               # Configuración específica de Android
├── ios/                   # Configuración específica de iOS
├── web/                   # Configuración específica de Web
├── pubspec.yaml          # Configuración de dependencias
└── analysis_options.yaml # Configuración de análisis de código
```

## Características

- Interfaz de usuario moderna con Material Design
- Soporte para múltiples plataformas (Android, iOS, Web)
- Arquitectura escalable
- Integración con el ecosistema FIWARE

## Pruebas

Ejecutar las pruebas:
```bash
flutter test
```

## Compilación

### Android
```bash
flutter build apk
```

### iOS
```bash
flutter build ios
```

### Web
```bash
flutter build web
```

## Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue o un pull request para sugerencias y mejoras.

## Licencia

Este proyecto es de código abierto.