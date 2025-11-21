class DeviceAttribute {
  final String name;
  final String type;
  final String? unit; // opcional

  DeviceAttribute({required this.name, required this.type, this.unit});

  // consultar datos
  factory DeviceAttribute.parseMap(Map<String, dynamic> json) {
    return DeviceAttribute(
      name: (json['name'] ?? json['object_id']) as String,
      type: (json['type'] ?? 'Text') as String,
      unit: json['unit'] as String?,
    );
  }

  // enviar datos
  Map<String, dynamic> toJson() {
    return {'object_id': name, 'name': name, 'type': type};
  }
}
