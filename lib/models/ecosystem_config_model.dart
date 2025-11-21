class EcosystemConfig {
  final String id;
  final String nombre;
  final String orionBaseUrl;
  final String iotAgentBaseUrl;
  final String quantumLeapBaseUrl;
  final String fiwareService;
  final String fiwareServicePath;
  final String apiKey;
  final List<String> protocolos;

  EcosystemConfig({
    required this.id,
    required this.nombre,
    required this.orionBaseUrl,
    required this.iotAgentBaseUrl,
    required this.quantumLeapBaseUrl,
    required this.fiwareService,
    required this.fiwareServicePath,
    required this.apiKey,
    required this.protocolos,
  });
}
