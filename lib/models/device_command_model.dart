class DeviceCommand {
  final String name;
  final String type;

  DeviceCommand({required this.name, required this.type});

  // consultar datos
  factory DeviceCommand.parseMap(Map<String, dynamic> json) {
    return DeviceCommand(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  // enviar datos
  Map<String, dynamic> toJson() {
    return {'name': name, 'type': type};
  }
}
